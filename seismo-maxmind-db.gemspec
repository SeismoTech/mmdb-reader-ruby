# frozen_string_literal: true

Gem::Specification.new do |s|
  s.authors = ['Seismo Technologies']
  s.files = Dir['**/*'].difference(Dir['.github/**/*', 'dev-bin/**/*'])
  s.name = 'seismo-maxmind-db'
  s.summary =
    'A performance oriented Gem to get IP info from MaxMind DB file format'
  s.version = '1.3.2'

  s.description =
    'A gem to get IP info from MaxMind DB file format.' \
    ' MaxMind DB is a binary file format that stores data' \
    ' indexed by IP address subnets (IPv4 or IPv6).'
  s.email = 'p@seismotech.com'
  s.homepage = 'https://github.com/SeismoTech/mmdb-reader-ruby'
  s.licenses = ['Apache-2.0', 'MIT']
  s.metadata = {
    'bug_tracker_uri' =>
    'https://github.com/SeismoTech/mmdb-reader-ruby/issues',
    'changelog_uri' =>
    'https://github.com/SeismoTech/mmdb-reader-ruby/blob/main/CHANGELOG.md',
    'documentation_uri' =>
    'https://www.rubydoc.info/gems/seismo-maxmind-db',
    'homepage_uri' =>
    'https://github.com/SeismoTech/mmdb-reader-ruby',
    'source_code_uri' =>
    'https://github.com/SeismoTech/mmdb-reader-ruby',
    'rubygems_mfa_required' =>
    'true',
  }
  s.required_ruby_version = '>= 3.0'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-performance'
end
