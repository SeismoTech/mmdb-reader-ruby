# frozen_string_literal: true

require 'seismo/mmdb/db_miner.rb'

module Seismo::MMDB
  # +Reader+ is the entry point to open a MaxMind DB for reading.
  # The main reason it exists is to create a Locator for its DB.
  # Nevertheless, it supports some low level DB exploration.
  class Reader
    attr_reader :miner

    def initialize(filename)
      @miner = DBMiner.new(filename)
    end

    def close
      @miner.close
    end

    def single_threaded = SingleThreaderReader.new(@miner)

    def metadata = @miner.metadata

    def get(ip)
      ipaddr = @miner.check_ip(ip)
      node = @miner.locate_addr(ipaddr.hton)
      ptr = @miner.check_data_pointer(node)
      ptr.nil? ? nil : @miner.value_decoder(ptr).decode
    end
  end
end
