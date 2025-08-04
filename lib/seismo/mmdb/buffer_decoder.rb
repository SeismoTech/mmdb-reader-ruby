# frozen_string_literal: true

module Seismo::MMDB
  # +Decoder+ ...
  class BufferDecoder
    MAX_OVERREAD = 7

    def initialize(buf, pointer_base, offset)
      @buf = buf
      @pointer_base = pointer_base
      @offset = offset
      @follow_pointers = true
      @ptr2key = nil
      @inkey = false
    end

    attr_reader :pointer_base
    attr_accessor :offset, :follow_pointers

    def remember_keys(enable = true)
      @ptr2key = enable ? Hash.new : nil if enable == @ptr2key.nil?
      self
    end

    def decode
      i = @offset
      control = @buf.get_value(:U8, i)
      i += 1

      type = control >> 5
      if type == 0
        type = 7 + @buf.get_value(:U8, i)
        i += 1
      end

      size = control & 0x1F
      if size < 29 || type == 1
        # noop
      elsif size == 29
        size = 29 + @buf.get_value(:U8, i)
        i += 1
      elsif size == 30
        size = 285 + @buf.get_value(:U16, i)
        i += 2
      else # size == 31
        # Safe overread by 1: because at least 65_821 bytes follow
        size = 65_821 + (@buf.get_value(:U32, i) >> 8)
        i += 3
      end

      @offset = i

      case type
      when 1 then decode_pointer(size)
      when 2 then decode_string(size)
      when 3 then decode_double
      when 4 then decode_bytes(size)
      when 5 then decode_uint16(size)
      when 6 then decode_uint32(size)
      when 7 then decode_map(size)
      when 8 then decode_sint32(size)
      when 9 then decode_uint64(size)
      when 10 then decode_uint128(size)
      when 11 then decode_array(size)
      when 12 then decode_container
      when 13 then decode_end
      when 14 then decode_boolean(size)
      when 15 then decode_float
      else
        unknown_type(type)
      end
    end

    private

    def unknown_type(type)
      raise BadDatabaseError, "Unknown type #{type}"
    end

    def decode_pointer(size)
      buf = @buf
      i = @offset
      ptr = size & 7
      case size >> 3
      when 0
        ptr = (ptr << 8) | buf.get_value(:U8, i)
        i += 1
      when 1
        ptr = ((ptr << 16) | buf.get_value(:U16, i)) + 2048
        i += 2
      when 2
        # Unsafe overread by 1
        ptr = ((ptr << 24) | (buf.get_value(:U32, i) >> 8)) + 526_336
        i += 3
      when 3
        ptr = buf.get_value(:U32, i)
        i += 4
      end
      ptr += @pointer_base

      if @follow_pointers
        if !@inkey || (x = @ptr2key[ptr]).nil?
          @offset = ptr
          x = decode
          @ptr2key[ptr] = x if @inkey
        end
      else
        x = ptr
      end
      @offset = i
      x
    end

    def decode_boolean(size)
      size != 0
    end

    def decode_uint16(size)
      return 0 if size == 0

      # Unsafe overread by upto 1
      x = @buf.get_value(:U16, @offset) >> (16 - (size << 3))
      @offset += size
      x
    end

    def decode_uint32(size)
      return 0 if size == 0

      # Unsafe overread by upto 3
      x = @buf.get_value(:U32, @offset) >> (32 - (size << 3))
      @offset += size
      x
    end

    def decode_uint64(size)
      return 0 if size == 0

      # Unsafe overread by upto 7
      x = @buf.get_value(:U64, @offset) >> (64 - (size << 3))
      @offset += size
      x
    end

    def decode_uint128(size)
      if size <= 8
        decode_uint64(size)
      else
        h = decode_uint64(size - 8)
        l = decode_uint64(8)
        (h << 64) | l
      end
    end

    def decode_sint32(size)
      return 0 if size == 0

      x = if size == 4
            @buf.get_value(:S32, @offset)
          else
            # Unsafe overread by upto 3
            @buf.get_value(:U32, @offset) >> (32 - (size << 3))
          end
      @offset += size
      x
    end

    def decode_float
      x = @buf.get_value(:F32, @offset)
      @offset += 4
      x
    end

    def decode_double
      x = @buf.get_value(:F64, @offset)
      @offset += 8
      x
    end

    def decode_string(size)
      x = @buf.get_string(@offset, size, Encoding::UTF_8)
      @offset += size
      x
    end

    def decode_bytes(size)
      x = @buf.get_string(@offset, size, Encoding::BINARY)
      @offset += size
      x
    end

    def decode_array(size)
      x = []
      i = 0
      while i < size
        x << decode
        i += 1
      end
      x
    end

    def decode_map(size)
      was_in_key = @inkey
      mark_in_key = !@ptr2key.nil?
      x = {}
      i = 0
      while i < size
        @inkey = mark_in_key
        k = decode
        @inkey = was_in_key
        v = decode
        x[k] = v
        i += 1
      end
      x
    end

    def decode_end
      raise 'TODO'
    end

    def decode_container
      raise 'TODO'
    end
  end
end
