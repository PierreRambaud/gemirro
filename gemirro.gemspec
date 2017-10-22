# -*- coding: utf-8 -*-
require 'date'
require File.expand_path('../lib/gemirro/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'gemirro'
  s.version     = Gemirro::VERSION
  s.date        = Date.today.to_s
  s.authors     = ['Pierre Rambaud']
  s.email       = 'pierre.rambaud86@gmail.com'
  s.license     = 'GPL-3.0'
  s.summary     = 'Gem for easily creating your own gems mirror.'
  s.homepage    = 'https://github.com/PierreRambaud/gemirro'
  s.description = 'Create your own gems mirror.'
  s.executables = ['gemirro']

  s.files = File.read(File.expand_path('../MANIFEST', __FILE__)).split("\n")

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'slop', '~>3.6'
  s.add_dependency 'httpclient', '~>2.6'
  s.add_dependency 'confstruct', '~>1.0'
  s.add_dependency 'builder', '~>3.2'
  s.add_dependency 'sinatra', '~>1.4'
  s.add_dependency 'thin', '~>1.6'
  s.add_dependency 'pmap', '~>1.1'

  s.add_development_dependency 'rake', '~>10.4'
  s.add_development_dependency 'rack-test', '~>0.6'
  s.add_development_dependency 'rspec', '~>3.2'
  s.add_development_dependency 'simplecov', '~>0.9'
  s.add_development_dependency 'rubocop', '~>0.35'
  s.add_development_dependency 'fakefs', '~>0.6.7'
end
