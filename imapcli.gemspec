# frozen_string_literal: true

require_relative 'lib/imapcli/version'

Gem::Specification.new do |s|
  s.name = 'imapcli'
  s.version = Imapcli::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = 'Daniel Kraus (bovender)'
  s.email = 'bovender@bovender.de'
  s.homepage = 'https://github.com/bovender/imapcli'
  s.summary = 'Command-line tool to query IMAP servers'
  s.license = 'Apache-2.0'

  s.required_ruby_version = '>= 3.1.0'

  s.files = `git ls-files`.split("\n")

  s.extra_rdoc_files = ['README.md', 'imapcli.rdoc']
  s.rdoc_options << '--title' << 'imapcli' << '--main' << 'README.md' << '-ri'

  s.bindir = 'exe'
  s.executables = ['imapcli']

  s.add_dependency('csv')
  s.add_dependency('descriptive_statistics', '~> 2.5')
  s.add_dependency('dotenv', '~> 2.2')
  s.add_dependency('filesize', '~> 0.1')
  s.add_dependency('gli', '~> 2.17')
  s.add_dependency('net-imap')
  s.add_dependency('tty-progressbar', '~> 0.13')
  s.add_dependency('tty-prompt', '~> 0.13')
  s.add_dependency('tty-table', '~> 0.9')
  s.add_dependency('zeitwerk', '~> 2.6.0')
end
