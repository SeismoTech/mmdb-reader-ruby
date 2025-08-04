# frozen_string_literal: true

module Seismo
  # FIXME: Document
  # Comment
  module MMDB
    DATA_SECTION_SEPARATOR_SIZE = 16

    METADATA_MAX_SIZE = 128 * 1024
    METADATA_MARKER = IO::Buffer.for("\xAB\xCD\xEFMaxMind.com".b)
    METADATA_MARKER_SIZE = METADATA_MARKER.size
    METADATA_LEGAL_RECORD_SIZES = [24, 28, 32].freeze
    METADATA_LEGAL_IP_VERSIONS = [4, 6].freeze
  end
end

require 'seismo/mmdb/errors.rb'
require 'seismo/mmdb/metadata.rb'
require 'seismo/mmdb/buffer_decoder.rb'
require 'seismo/mmdb/db_miner.rb'
require 'seismo/mmdb/reader.rb'
require 'seismo/mmdb/single_threaded_reader.rb'
