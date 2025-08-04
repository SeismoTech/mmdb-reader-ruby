# frozen_string_literal: true

require 'benchmark/ips'
require 'ipaddr'
require 'maxmind/db'
require 'seismo/mmdb'

READER_FILE = MaxMind::DB.new(
  'mmdbs/GeoLite2-City.mmdb',
  mode: MaxMind::DB::MODE_FILE
)
READER_MEMORY = MaxMind::DB.new(
  'mmdbs/GeoLite2-City.mmdb',
  mode: MaxMind::DB::MODE_MEMORY
)
READER6 = Seismo::MMDB::Reader.new('mmdbs/GeoLite2-City.mmdb')
READER6_ST = READER6.single_threaded

def random_ipv4
  IPAddr.new_ntoh(Random.bytes(4))
end

Benchmark.ips do |x|
  # To check the impact of random ip generation
  x.report 'Random ip' do
    random_ipv4
  end

  x.report 'MaxMind file' do
    READER_FILE.get(random_ipv4)
  end

  x.report 'MaxMind memory' do
    READER_MEMORY.get(random_ipv4)
  end

  x.report 'seismo buffer' do
    READER6.get(random_ipv4)
  end

  x.report 'seismo buffer single threaded' do
    READER6_ST.get(random_ipv4)
  end
end
