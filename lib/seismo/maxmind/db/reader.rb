# frozen_string_literal: true

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
      @buffer = buf
      @metadata_offset = mdoff
      @metadata = md
    end

    attr_reader :metadata
    attr_reader :metadata_offset
    attr_reader :buffer

    def self.find_metadata_start(filename, size, buf)
      above = [0, size - METADATA_MAX_SIZE].max
      i = size - METADATA_MARKER_SIZE
      while above <= i && buf.slice(i, METADATA_MARKER_SIZE) != METADATA_MARKER
        i -= 1
      end
      return i + METADATA_MARKER_SIZE if above <= i
      Seismo::MaxMind::DB::BadDatabaseError
        .cannot_find_metadata_marker(filename)
    end

    def locator = Locator.new self

    def close
      @buffer.free
      @file.close
    end
  end
end
