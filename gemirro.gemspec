# frozen_string_literal: true

require 'date'
require File.expand_path('../lib/gemirro/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'gemirro'
  s.version     = Gemirro::VERSION
  s.authors     = ['Pierre Rambaud']
  s.email       = 'pierre.rambaud86@gmail.com'
  s.license     = 'GPL-3.0'
  s.summary     = 'Gem for easily creating your own gems mirror.'
  s.homepage    = 'https://github.com/PierreRambaud/gemirro'
  s.description = 'Create your own gems mirror.'
  s.executables = ['gemirro']

  s.files = File.read(File.expand_path('../MANIFEST', __FILE__)).split("\n")

  s.required_ruby_version = '>= 2.5'

  s.add_dependency 'addressable', '~>2.8'
  s.add_dependency 'builder', '~>3.2'
  s.add_dependency 'confstruct', '~>1.1'
  s.add_dependency 'erubis', '~>2.7'
  s.add_dependency 'httpclient', '~>2.8'
  s.add_dependency 'parallel', '~>1.21'
  s.add_dependency 'sinatra', '>=2.1', '<4.0'
  s.add_dependency 'sinatra-static-assets', '~>1.0'
  s.add_dependency 'slop', '~>3.6'
  s.add_dependency 'thin', '~>1.8'

  s.add_development_dependency 'fakefs', '~>1'
  s.add_development_dependency 'rack-test', '~>1.1'
  s.add_development_dependency 'rake', '~>13'
  s.add_development_dependency 'rspec', '~>3.10'
  s.add_development_dependency 'rubocop', '~>1'
  s.add_development_dependency 'simplecov', '~>0.21'
end
