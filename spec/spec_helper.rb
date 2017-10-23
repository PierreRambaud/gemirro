$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'simplecov'
require 'confstruct'
require 'logger'
require 'fakefs/spec_helpers'

SimpleCov.start do
  add_filter '/spec/'
end
