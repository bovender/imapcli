# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','imapcli','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'imapcli'
  s.version = Imapcli::VERSION
  s.author = 'Daniel Kraus (bovender)'
  s.email = 'bovender@bovender.de'
  s.homepage = 'https://github.com/bovender/imapcli'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A description of your project'
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc','imapcli.rdoc']
  s.rdoc_options << '--title' << 'imapcli' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'imapcli'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_runtime_dependency('gli','2.17.0')
end