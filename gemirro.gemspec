# -*- coding: utf-8 -*-
require File.expand_path('../lib/gemirro/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'gemirro'
  s.version     = Gemirro::VERSION
  s.date        = '2014-08-19'
  s.authors     = ['Pierre Rambaud']
  s.email       = 'pierre.rambaud86@gmail.com'
  s.license     = 'GPL-3.0'
  s.summary     = 'Gem for easily creating your own RubyGems mirror.'
  s.homepage    = 'https://github.com/PierreRambaud/gemirro'
  s.description = 'Create your own gem mirror with a simple TCPServer.'
  s.executables = ['gemirro']

  s.files = File.read(File.expand_path('../MANIFEST', __FILE__)).split("\n")

  s.required_ruby_version = '~> 1.9.2'

  s.add_dependency 'slop', '~>3.6'
  s.add_dependency 'httpclient', '~>2.4'
  s.add_dependency 'confstruct', '~>0.2'
  s.add_dependency 'builder', '~>3.2'

  s.add_development_dependency 'mime-types', '~>2.3'
  s.add_development_dependency 'rake', '~>10.0'
  s.add_development_dependency 'rspec', '~>3.0'
  s.add_development_dependency 'simplecov', '~>0.9'
  s.add_development_dependency 'rubocop', '~>0.25'
  s.add_development_dependency 'fakefs', '~>0.5'
end
