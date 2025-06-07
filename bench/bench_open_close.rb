require 'benchmark/ips'
require 'ipaddr'
require 'maxmind/db'
require 'seismo/maxmind/db'

IP = IPAddr.new '80.37.70.128'
DBNAME = 'mmdbs/GeoLite2-City.mmdb'

Benchmark.ips do |x|
  x.report 'MaxMind file' do
    reader = MaxMind::DB.new(DBNAME, mode: MaxMind::DB::MODE_FILE)
    info = reader.get(IP)
    reader.close
    info
  end

  x.report 'MaxMind memory' do
    reader = MaxMind::DB.new(DBNAME, mode: MaxMind::DB::MODE_MEMORY)
    info = reader.get(IP)
    reader.close
    info
  end

  x.report 'seismo' do
    reader = Seismo::MaxMind::DB::Reader.new(DBNAME)
    loc = reader.locator
    info = loc.locate(IP)
    reader.close
    info
  end
end
