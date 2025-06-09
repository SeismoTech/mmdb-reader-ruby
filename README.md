MaxMind Database reader for Ruby
======================================================================

This is a fork of [the official MaxMind DB reader for Ruby](
https://github.com/maxmind/MaxMind-DB-Reader-ruby).
The goal is to improve the performance, particularly when using YJIT.
The library code has been written from scratch,
but the project structure and most of the tests were copied from the official
reader.

The current code is based on memory mapped files,
although, as of Ruby 3.5, it is still an experimental feature.

Prelimary benchmarks against the official MaxMind DB reader Gem shows
promising results:

- Finding a fixed IP

| | YJIT off | YJIT on |
|-|-|-|
|MaxMind File  | 1.240k i/s | 1.677k i/s |
|MaxMind Memory| 2.761k i/s | 4.471k i/s |
|Seismo Buffer | 7.616k i/s | 19.521k i/s |

- Finding a random IP:

| | YJIT off | YJIT on |
|-|-|-|
|MaxMind File  |  1.941k i/s |  2.496k i/s |
|MaxMind Memory|  4.136k i/s |  6.439k i/s |
|Seismo Buffer | 10.139k i/s | 23.655k i/s |

- Open, locate and close a fixed IP:

| | YJIT off | YJIT on |
|-|-|-|
|MaxMind File  | 763.811 i/s | 1.014k i/s |
|MaxMind Memory|  26.053 i/s | 26.210 i/s |
|Seismo Buffer |  2.386k i/s | 3.606k i/s |
