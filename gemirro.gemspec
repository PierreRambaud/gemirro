# -*- coding: utf-8 -*-
require File.expand_path('../lib/gemirro/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'gemirro'
  s.version     = Gemirro::VERSION
  s.date        = '2014-08-19'
  s.authors     = ['Pierre Rambaud']
  s.email       = 'pierre.rambaud86@gmail.com'
  s.summary     = 'Gem for easily creating your own RubyGems mirror.'
  s.homepage    = 'https://github.com/PierreRambaud/gemirro'
  s.description = s.summary
  s.executables = ['gemirro']

  s.files = File.read(File.expand_path('../MANIFEST', __FILE__)).split("\n")

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'slop'
  s.add_dependency 'httpclient'
  s.add_dependency 'confstruct'
  s.add_dependency 'builder'

  s.add_development_dependency 'mime-types'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'fakefs'
end
