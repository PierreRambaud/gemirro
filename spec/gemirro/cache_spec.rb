# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/mirror_directory'
require 'gemirro/cache'

# Gem tests
module Gemirro
  describe 'Cache' do
    include FakeFS::SpecHelpers
    before(:each) do
      MirrorDirectory.new('/tmp')
      @cache = Cache.new('/tmp')
    end

    it 'should play with flush key' do
      @cache.cache('foo') do
        'something'
      end
      expect(@cache.cache('foo')).to eq('something')
      @cache.flush_key('foo')
      expect(@cache.cache('foo')).to be_nil
    end

    it 'should play with flush' do
      @cache.cache('foo') do
        'something'
      end
      expect(@cache.cache('foo')).to eq('something')
      @cache.flush
      expect(@cache.cache('foo')).to be_nil
    end
  end
end
