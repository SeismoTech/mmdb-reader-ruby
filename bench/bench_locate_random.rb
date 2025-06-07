require 'benchmark/ips'
require 'ipaddr'
require 'maxmind/db'
require 'seismo/maxmind/db'

READER_FILE = MaxMind::DB.new(
  'mmdbs/GeoLite2-City.mmdb',
  mode: MaxMind::DB::MODE_FILE
)
READER_MEMORY = MaxMind::DB.new(
  'mmdbs/GeoLite2-City.mmdb',
  mode: MaxMind::DB::MODE_MEMORY
)
LOC = Seismo::MaxMind::DB::Reader.new('mmdbs/GeoLite2-City.mmdb').locator

def random_ipv4
  IPAddr.new_ntoh(Random.bytes(4))
end

Benchmark.ips do |x|
  x.report 'MaxMind file' do
    READER_FILE.get(random_ipv4)
  end

  x.report 'MaxMind memory' do
    READER_MEMORY.get(random_ipv4)
  end

  x.report 'seismo' do
    LOC.locate(random_ipv4)
  end
end
