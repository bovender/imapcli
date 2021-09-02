# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','imapcli','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'imapcli'
  s.version = Imapcli::VERSION
  s.author = 'Daniel Kraus (bovender)'
  s.email = 'bovender@bovender.de'
  s.homepage = 'https://github.com/bovender/imapcli'
  s.license = 'Apache-2.0'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Command-line tool to query IMAP servers'
  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.extra_rdoc_files = ['README.md','imapcli.rdoc']
  s.rdoc_options << '--title' << 'imapcli' << '--main' << 'README.md' << '-ri'
  s.bindir = 'bin'
  s.executables << 'imapcli'
  s.add_development_dependency('rake', '~> 12.3.3')
  s.add_development_dependency('rdoc', '~> 6.3')
  s.add_runtime_dependency('descriptive_statistics', '~> 2.5')
  s.add_runtime_dependency('dotenv', '~> 2.2')
  s.add_runtime_dependency('filesize', '~> 0.1')
  s.add_runtime_dependency('gli','~> 2.17')
  s.add_runtime_dependency('tty-progressbar', '~> 0.13')
  s.add_runtime_dependency('tty-prompt', '~> 0.13')
  s.add_runtime_dependency('tty-table', '~> 0.9')
end
