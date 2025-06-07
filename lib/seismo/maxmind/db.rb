# frozen_string_literal: true

module Seismo
  module MaxMind
    # FIXME: Document
    # Comment
    module DB
      DATA_SECTION_SEPARATOR_SIZE = 16

      METADATA_MAX_SIZE = 128 * 1024
      METADATA_MARKER = IO::Buffer.for("\xAB\xCD\xEFMaxMind.com".b)
      METADATA_MARKER_SIZE = METADATA_MARKER.size
      METADATA_LEGAL_RECORD_SIZES = [24, 28, 32].freeze
      METADATA_LEGAL_IP_VERSIONS = [4, 6].freeze
    end
  end
end

require 'seismo/maxmind/db/errors'
require 'seismo/maxmind/db/metadata'
require 'seismo/maxmind/db/buffer_decoder'
require 'seismo/maxmind/db/reader'
require 'seismo/maxmind/db/locator'
