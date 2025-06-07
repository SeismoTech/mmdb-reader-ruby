# frozen_string_literal: true

require 'ipaddr'

module Seismo::MaxMind::DB
  # +Locator+ ...
  class Locator
    def initialize(reader)
      md = reader.metadata

      @buf = reader.buffer
      @mdoff = reader.metadata_offset
      @nodes = md.node_count
      @ipv4 = md.ipv4?

      @nodebytes = 2*md.record_size / 8
      @treebytes = @nodes * @nodebytes
      @dataoff = @treebytes + DATA_SECTION_SEPARATOR_SIZE
      @ipv4root = @ipv4 ? 0 : find_ipv4root
    end

    def ipv4? = @ipv4
    def ipv6? = !@ipv6

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

    private

    def locate_addr(addr)
      blocks = addr.size
      nodes = @nodes
      node = blocks == 4 ? @ipv4root : 0
      #puts("Initial node #{node} of #{@nodes}")
      i = 0
      while i < blocks && node < nodes
        block = addr.getbyte(i)
        #puts("Block #{block}")
        j = 0
        while j < 8 && node < nodes
          branch = (block >> (7-j)) & 1
          node = read_branch(node, branch)
          #puts("Branch #{branch} points to node #{node} of #{@nodes}")
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
      #puts("Initial node #{node} of #{@nodes}")
      i = 0
      while i < blocks
        block = addr.getbyte(i)
        #puts("Block #{block}")
        j = 0
        while j < 8
          branch = (block >> (7-j)) & 1
          node = read_branch(node, branch)
          return node if nodes <= node
          #puts("Branch #{branch} points to node #{node} of #{@nodes}")
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
      #puts("find ipv4root #{i} #{node}")
      node
    end

    def read_branch(node, branch)
      off = node * @nodebytes
      #puts("Read branch #{node} #{branch} #{off}")
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
      #puts("Decode #{ptr} of #{@buf.size}")
      BufferDecoder.new(@buf, @dataoff, ptr).decode
    end
  end
end
