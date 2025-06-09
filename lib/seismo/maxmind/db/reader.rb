# frozen_string_literal: true

require 'ipaddr'
require 'seismo/maxmind/db/errors'
require 'seismo/maxmind/db/buffer_decoder'

module Seismo::MaxMind::DB
  # +Reader+ is the entry point to open a MaxMind DB for reading.
  # The main reason it exists is to create a Locator for its DB.
  # Nevertheless, it supports some low level DB exploration.
  class Reader
    EXTRAMAP = Seismo::MaxMind::DB::BufferDecoder::MAX_OVERREAD

    def initialize(filename)
      file = File.open(filename)
      begin
        size = file.size
        buf = IO::Buffer.map(file, size+EXTRAMAP, 0, IO::Buffer::READONLY)
        mdoff = Reader.find_metadata_start(filename, size, buf)
        mdmap = Seismo::MaxMind::DB::BufferDecoder.new(buf, mdoff, mdoff).decode
        md = Metadata.new(mdmap)
      rescue StandardError => e
        file.close
        raise e
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
      @treebytes = @nodes * @nodebytes
      @dataoff = @treebytes + DATA_SECTION_SEPARATOR_SIZE
      @ipv4root = @ipv4 ? 0 : find_ipv4root
    end

    attr_reader :metadata

    def metadata_offset = @mdoff
    def buffer = @buf

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

    def locate(ip)
      ipaddr = ip.is_a?(IPAddr) ? ip : IPAddr.new(ip)
      if ipaddr.ipv6? && @ipv4
        raise ArgumentError,
              "Cannot search the IPv6 address #{ipaddr} in an IPv4 database"
      end

      node = locate_addr(ipaddr.hton)

      if @nodes + DATA_SECTION_SEPARATOR_SIZE <= node
        ptr = (node - @nodes) + @treebytes
        load_value(ptr)
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

    alias_method :get, :locate # rubocop:disable Style/Alias

    private

    def locate_addr(addr)
      blocks = addr.size
      nodes = @nodes
      node = blocks == 4 ? @ipv4root : 0
      # puts("Initial node #{node} of #{@nodes}")
      i = 0
      while i < blocks && node < nodes
        block = addr.getbyte(i)
        # puts("Block #{block}")
        j = 0
        while j < 8 && node < nodes
          branch = (block >> (7-j)) & 1
          node = read_branch(node, branch)
          # puts("Branch #{branch} points to node #{node} of #{@nodes}")
          j += 1
        end
        i += 1
      end
      node
    end

    def locate_addr1(addr)
      blocks = addr.size
      nodes = @nodes
      node = blocks == 4 ? @ipv4root : 0
      return node if nodes <= node

      # puts("Initial node #{node} of #{@nodes}")
      i = 0
      while i < blocks
        block = addr.getbyte(i)
        # puts("Block #{block}")
        j = 0
        while j < 8
          branch = (block >> (7-j)) & 1
          node = read_branch(node, branch)
          return node if nodes <= node

          # puts("Branch #{branch} points to node #{node} of #{@nodes}")
          j += 1
        end
        i += 1
      end
      node
    end

    def find_ipv4root
      node = 0
      i = 0
      while i < 96 && node < @nodes
        node = read_branch(node, 0)
        i += 1
      end
      # puts("find ipv4root #{i} #{node}")
      node
    end

    def read_branch(node, branch)
      off = node * @nodebytes
      # puts("Read branch #{node} #{branch} #{off}")
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

    def load_value(ptr)
      # puts("Decode #{ptr} of #{@buf.size}")
      BufferDecoder.new(@buf, @dataoff, ptr).decode
    end
  end
end
