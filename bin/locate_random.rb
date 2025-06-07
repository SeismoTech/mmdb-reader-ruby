require 'maxmind/db'
require 'seismo/maxmind/db'

DBNAME = ARGV[0]
mmreader = MaxMind::DB.new(DBNAME)
reader = Seismo::MaxMind::DB::Reader.new(DBNAME)
puts(reader.metadata.inspect)
loc = reader.locator
loop do
  ip = IPAddr.new_ntoh(Random.bytes(4))
  puts("#{ip}")
  info1 = mmreader.get(ip)
  puts(">>>  #{info1}")
  info2 = loc.locate(ip)
  puts(">>>  #{info2}")
  break if info1 != info2
end
