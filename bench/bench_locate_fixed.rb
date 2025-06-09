# frozen_string_literal: true

require 'benchmark/ips'
require 'ipaddr'
require 'maxmind/db'
require 'seismo/maxmind/db'

IP = IPAddr.new '80.37.70.128'
READER_FILE = MaxMind::DB.new(
  'mmdbs/GeoLite2-City.mmdb',
  mode: MaxMind::DB::MODE_FILE
)
READER_MEMORY = MaxMind::DB.new(
  'mmdbs/GeoLite2-City.mmdb',
  mode: MaxMind::DB::MODE_MEMORY
)
READER6 = Seismo::MaxMind::DB::Reader.new('mmdbs/GeoLite2-City.mmdb')

Benchmark.ips do |x|
  x.report 'MaxMind file' do
    READER_FILE.get(IP)
  end

  x.report 'MaxMind memory' do
    READER_MEMORY.get(IP)
  end

  x.report 'seismo' do
    READER6.get(IP)
  end
end
