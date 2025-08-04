# frozen_string_literal: true

module Seismo::MaxMind::DB
  # +Decoder+ ...
  class SingleThreaderReader
    def initialize(miner)
      @miner = miner
      @decoder = miner.value_decoder(0).remember_keys;
    end

    def close
      @miner.close
    end

    def metadata = @miner.metadata

    def get(ip)
      ipaddr = @miner.check_ip(ip)
      node = @miner.locate_addr(ipaddr.hton)
      ptr = @miner.check_data_pointer(node)
      return nil if ptr.nil?

      @decoder.offset = ptr
      @decoder.decode
    end
  end
end
