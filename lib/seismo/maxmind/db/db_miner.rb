# frozen_string_literal: true

require 'ipaddr'
require 'seismo/maxmind/db/errors.rb'
require 'seismo/maxmind/db/buffer_decoder.rb'

module Seismo::MaxMind::DB
  # A +DBMiner+ is an internal class doing all the heavy decoding stuff
  # of a MMDB file.
  # There are 2 public classes leveraging this class funcionality:
  # Reader and SingleThreadedReader
  class DBMiner
    EXTRAMAP = Seismo::MaxMind::DB::BufferDecoder::MAX_OVERREAD

    def initialize(filename)
      file = nil
      buf = nil
      begin
        file = File.open(filename)
        size = file.size
        buf = IO::Buffer.map(file, size+EXTRAMAP, 0, IO::Buffer::READONLY)
        mdoff = DBMiner.find_metadata_start(filename, size, buf)
        mdmap = Seismo::MaxMind::DB::BufferDecoder.new(buf, mdoff, mdoff).decode
        md = Metadata.new(mdmap)
      rescue
        buf.free unless buf.nil?
        file.close unless file.nil?
        raise
      end

      @filename = filename
      @file = file
      @size = size
      @buf = buf

      @metadata = md
      @mdoff = mdoff

      @ipv4 = md.ipv4?
      @nodes = md.node_count
      @nodebytes = 2*md.record_size / 8
      treebytes = @nodes * @nodebytes
      @ptrshift = treebytes - @nodes
      @dataoff = treebytes + DATA_SECTION_SEPARATOR_SIZE
      @ipv4root = @ipv4 ? 0 : find_ipv4root
    end

    attr_reader :metadata

    def node_count = @nodes
    def buffer = @buf

    def file_size = @size
    def data_offset = @dataoff
    def pointer_shift = @ptrshift
    def metadata_offset = @mdoff

    def self.find_metadata_start(filename, size, buf)
      above = [0, size - METADATA_MAX_SIZE].max
      i = size - METADATA_MARKER_SIZE
      i -= 1 while
        above <= i && buf.slice(i, METADATA_MARKER_SIZE) != METADATA_MARKER
      return i + METADATA_MARKER_SIZE if above <= i

      Seismo::MaxMind::DB::BadDatabaseError
        .cannot_find_metadata_marker(filename)
    end

    def close
      @buf.free
      @file.close
    end

    def locator = Locator::new self

    def locate(ip)
      ipaddr = check_ip(ip)
      node = locate_addr(ipaddr.hton)
      ptr = check_data_pointer(node)
      load_value(ptr)
    end

    alias_method :get, :locate # rubocop:disable Style/Alias

    def check_ip(ip)
      ipaddr = ip.is_a?(IPAddr) ? ip : IPAddr.new(ip)
      if ipaddr.ipv6? && @ipv4
        raise ArgumentError,
              "Cannot search the IPv6 address #{ipaddr} in an IPv4 database"
      end
      ipaddr
    end

    def locate_addr(addr)
      blocks = addr.size
      nodes = @nodes
      node = blocks == 4 ? @ipv4root : 0
      i = 0
      while i < blocks && node < nodes
        block = addr.getbyte(i)
        j = 0
        while j < 8 && node < nodes
          branch = (block >> (7-j)) & 1
          node = read_branch(node, branch)
          j += 1
        end
        i += 1
      end
      node
    end

    def check_data_pointer(node)
      if @nodes + DATA_SECTION_SEPARATOR_SIZE <= node
        node + @ptrshift
      elsif @nodes < node
        raise BadDatabaseError,
              "Illegal record value #{node} in [#{@nodes+1}, #{nodes+15}]"
      elsif node == @nodes
        nil
      elsif node < @nodes
        raise BadDatabaseError,
              "IP #{ipaddr} ended before reaching a tree leaf"
      end
    end

    def value_decoder(ptr) = BufferDecoder.new(@buf, @dataoff, ptr)

    def traverse_depth_first(&action)
      tdp(0, 0, "\0".b*16, Set.new, action)
    end

    alias_method :traverse, :traverse_depth_first

    private

    # An alternative with no clear performance difference
    # def locate_addr(addr)
    #   blocks = addr.size
    #   nodes = @nodes
    #   node = blocks == 4 ? @ipv4root : 0
    #   return node if nodes <= node

    #   i = 0
    #   while i < blocks
    #     block = addr.getbyte(i)
    #     j = 0
    #     while j < 8
    #       branch = (block >> (7-j)) & 1
    #       node = read_branch(node, branch)
    #       return node if nodes <= node

    #       j += 1
    #     end
    #     i += 1
    #   end
    #   node
    # end

    def tdp(node, depth, addr, visited, action)
      return unless node < @nodes && !visited.include?(node)

      visited << node

      child = read_branch(node, 0)
      action.call(node, 0, child, addr, depth+1)
      tdp(child, depth+1, addr, visited, action)

      child = read_branch(node, 1)
      bit_set(addr, depth)
      action.call(node, 1, child, addr, depth+1)
      tdp(child, depth+1, addr, visited, action)
      bit_unset(addr, depth)
    end

    def bit_set(addr, i)
      b = i >> 3
      addr.setbyte(b, addr.getbyte(b) | (0x80 >> (i & 7)))
    end

    def bit_unset(addr, i)
      b = i >> 3
      addr.setbyte(b, addr.getbyte(b) & ~(0x80 >> (i & 7)))
    end

    def find_ipv4root
      node = 0
      i = 0
      while i < 96 && node < @nodes
        node = read_branch(node, 0)
        i += 1
      end
      node
    end

    def read_branch(node, branch)
      off = node * @nodebytes
      case @nodebytes
      when 6
        @buf.get_value(:U32, off + 3*branch) >> 8
      when 7
        v = @buf.get_value(:U32, off + 3*branch)
        branch == 0 ? (v >> 8) | ((v & 0xF0) << 20) : v & 0xFFFFFFF
      when 8
        @buf.get_value(:U32, off + (branch << 2))
      end
    end
  end
end
