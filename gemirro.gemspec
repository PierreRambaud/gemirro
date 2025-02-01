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

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'addressable', '~>2.8'
  s.add_dependency 'builder', '~>3.2'
  s.add_dependency 'compact_index', '~> 0.15'
  s.add_dependency 'confstruct', '~>1.1'
  s.add_dependency 'erubis', '~>2.7'
  s.add_dependency 'httpclient', '~>2.8'
  s.add_dependency 'parallel', '~>1.21'
  s.add_dependency 'sinatra', '>=3.1', '<4.0'
  s.add_dependency 'slop', '~>3.6'
  s.add_dependency 'stringio', '~> 3.1'
  s.add_dependency 'thin', '~>1.8'

  s.metadata['rubygems_mfa_required'] = 'true'
end
