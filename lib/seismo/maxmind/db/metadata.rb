# frozen_string_literal: true

module Seismo::MaxMind::DB
  # Doc
  class Metadata
    # Doc
    attr_reader :major_version

    # Doc
    attr_reader :minor_version

    # Doc
    attr_reader :node_count

    # Doc
    attr_reader :record_size

    # Doc
    attr_reader :ip_version

    # Doc
    attr_reader :database_type

    # Doc
    attr_reader :build_epoch

    # Doc
    attr_reader :languages

    # Doc
    attr_reader :description

    def ipv4? = @ip_version == 4
    def ipv6? = @ip_version == 6

    def initialize(map)
      Metadata.check(map)
      @major_version = map['binary_format_major_version']
      @minor_version = map['binary_format_minor_version']
      @node_count = map['node_count']
      @record_size = map['record_size']
      @ip_version = map['ip_version']
      @database_type = map['database_type']
      @build_epoch = map['build_epoch']
      @languages = map['languages']
      @description = map['description']
    end

    def self.check(map)
      check_field(map, 'binary_format_major_version') { |v| v == 2 }
      check_field(map, 'binary_format_minor_version') do |v|
        v.is_a?(Integer) && v >= 0
      end
      check_field(map, 'node_count') { |v| v.is_a?(Integer) && v > 0 }
      check_field(map, 'record_size') do |v|
        METADATA_LEGAL_RECORD_SIZES.include?(v)
      end
      check_field(map, 'ip_version') do |v|
        METADATA_LEGAL_IP_VERSIONS.include?(v)
      end
      check_field(map, 'database_type') { |v| v.is_a?(String) }
      check_field(map, 'build_epoch') { |v| v.is_a?(Integer) }
      check_field(map, 'languages') do |v|
        v.nil? || (v.is_a?(Array) && v.all?(String))
      end
      check_field(map, 'description') do |d|
        d.nil? \
        || (d.is_a?(Hash) \
            && d.all? { |k, v| k.is_a?(String) && v.is_a?(String) })
      end
    end

    def self.check_field(map, field_name)
      value = map[field_name]
      unless yield value
        raise BadDatabaseError,
              "Illegal metadata field #{field_name} value #{value}"
      end
      value
    end

    def each
      yield 'mayor version', @major_version
      yield 'minor version', @minor_version
      yield 'node count', @node_count
      yield 'record size', @record_size
      yield 'ip_version', @ip_version
      yield 'database_type', @database_type
      yield 'build_epoch', @build_epoch
      yield 'languages', @language
      yield 'description', @description
    end
  end
end
