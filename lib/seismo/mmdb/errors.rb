# frozen_string_literal: true

module Seismo::MMDB
  # Doc
  class BadDatabaseError < RuntimeError
    def self.cannot_find_metadata_marker(filename)
      raise BadDatabaseError, "Cannot find metadata start marker at #{filename}"
    end
  end
end
