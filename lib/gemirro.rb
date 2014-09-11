# -*- coding: utf-8 -*-
require 'rubygems'
require 'rubygems/user_interaction'
require 'rubygems/indexer'
require 'slop'
require 'fileutils'
require 'digest/sha2'
require 'confstruct'
require 'zlib'
require 'httpclient'
require 'logger'
require 'stringio'

unless $LOAD_PATH.include?(File.expand_path('../', __FILE__))
  $LOAD_PATH.unshift(File.expand_path('../', __FILE__))
end

require 'gemirro/version'
require 'gemirro/configuration'
require 'gemirro/gem'
require 'gemirro/http'
require 'gemirro/indexer'
require 'gemirro/source'
require 'gemirro/mirror_directory'
require 'gemirro/mirror_file'
require 'gemirro/versions_file'
require 'gemirro/versions_fetcher'
require 'gemirro/gems_fetcher'

require 'gemirro/cli'
require 'gemirro/cli/init'
require 'gemirro/cli/update'
require 'gemirro/cli/index'
require 'gemirro/cli/server'
