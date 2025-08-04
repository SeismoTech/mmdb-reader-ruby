# frozen_string_literal: true

require 'maxmind/db'
require 'seismo/mmdb'

DBNAME = ARGV[0]
mmreader = MaxMind::DB.new(DBNAME)
reader = Seismo::MMDB::Reader.new(DBNAME)
puts(reader.metadata.inspect)
loc = reader.single_threaded
loop do
  ip = IPAddr.new_ntoh(Random.bytes(4))
  puts(ip)
  info1 = mmreader.get(ip)
  puts(">>> #{info1}")
  info2 = loc.get(ip)
  puts(">>> #{info2}")
  puts
  break if info1 != info2
end
