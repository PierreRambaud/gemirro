# -*- coding: utf-8 -*-
require 'bundler/gem_tasks'

GEMSPEC = Gem::Specification.load('gemirro.gemspec')

Dir['./task/*.rake'].each do |task|
  import(task)
end

task default: [:spec, :rubocop]
