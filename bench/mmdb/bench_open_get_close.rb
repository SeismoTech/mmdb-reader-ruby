# frozen_string_literal: true

require 'benchmark/ips'
require 'ipaddr'
require 'maxmind/db'
require 'seismo/mmdb'

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
    reader = Seismo::MMDB::Reader.new(DBNAME)
    info = reader.get(IP)
    reader.close
    info
  end

  x.compare!
end
