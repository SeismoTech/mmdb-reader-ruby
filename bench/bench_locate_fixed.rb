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
LOC = Seismo::MaxMind::DB::Reader.new('mmdbs/GeoLite2-City.mmdb').locator

Benchmark.ips do |x|
  x.report 'MaxMind file' do
    READER_FILE.get(IP)
  end

  x.report 'MaxMind memory' do
    READER_MEMORY.get(IP)
  end

  x.report 'seismo' do
    LOC.locate(IP)
  end
end
