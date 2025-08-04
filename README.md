MaxMind Database reader for Ruby
======================================================================

This is a fork of [the official MaxMind DB reader for Ruby](
https://github.com/maxmind/MaxMind-DB-Reader-ruby).
The goal is to improve the performance, particularly when using YJIT.

The library code has been written from scratch,
but the project structure and most of the tests were copied from the official
reader.

The current code is based on `IO::Buffer` with memory mapped files.
Keep in mind that, as of Ruby 3.5, `IO::Buffer` is still experimental
and memory mapping could even be removed in the future XD.

A few benchmarks against the official MaxMind DB reader Gem shows
a sensible performance improvement:

- Finding a fixed IP

| | YJIT off | YJIT on |
|-|-|-|
|MaxMind File                 | 1.302k i/s | 1.677k i/s |
|MaxMind Memory               | 1.302k i/s | 4.471k i/s |
|Seismo Buffer                | 7.616k i/s | 19.521k i/s |
|Seismo Buffer Single Threaded| 9.721k i/s | 25.650k i/s |

- Finding a random IP:

| | YJIT off | YJIT on |
|-|-|-|
|MaxMind File                 |  1.941k i/s |  2.599k i/s |
|MaxMind Memory               |  4.136k i/s |  6.439k i/s |
|Seismo Buffer                |  9.887k i/s | 23.293k i/s |
|Seismo Buffer Single Threaded| 11.945k i/s | 28.252k i/s |

- Open, locate a fixed IP and close:

| | YJIT off | YJIT on |
|-|-|-|
|MaxMind File  | 763.811 i/s | 1.014k i/s |
|MaxMind Memory|  26.053 i/s | 26.210 i/s |
|Seismo Buffer |  2.386k i/s | 3.606k i/s |


API
----------------------------------------------------------------------

API is pretty simple and follows MaxMind API.

Open a mmdb file with
```ruby
require 'seismo/maxmind/db'

reader = Seismo::MMDB::Reader.new('database.mmdb')
```
Get IP information with
```ruby
ipinfo = reader.get(ip)
```
where `ip` is either a `IPAddr` or a `String` with the textual representation
of an IP (either IPv4 or IPv6).

Close the `reader` when you are done:
```ruby
reader.close
```

Database metainformation is available at
```ruby
dbinfo = reader.metadata
```

`Seismo::MMDB::Reader` is thread safe.
There is a *single threaded* version with better performance.
Each *thread* (or similar) should get is own instance with 
`reader.single_threaded`.
