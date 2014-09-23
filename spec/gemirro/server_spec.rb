# -*- coding: utf-8 -*-
require 'rack/test'
require 'gemirro/mirror_directory'
require 'gemirro/mirror_file'

ENV['RACK_ENV'] = 'test'

# Rspec mixin module
module RSpecMixin
  include Rack::Test::Methods
  def app
    require 'gemirro/server'
    Gemirro::Server
  end
end

RSpec.configure do |c|
  c.include RSpecMixin
end

# Server tests
module Gemirro
  describe 'Gemirro::Server' do
    include FakeFS::SpecHelpers

    before(:each) do
      MirrorDirectory.new('/var/www/gemirro').add_directory('gems')
      MirrorDirectory.new('/').add_directory('tmp')
      MirrorFile.new('/var/www/gemirro/test').write('content')
      Gemirro.configuration.destination = '/var/www/gemirro'
    end

    it 'should display directory' do
      get '/'
      expect(last_response.body).to eq('<a href="/gems">gems/</a><br>' \
                                       '<a href="/test">test</a><br>')
      expect(last_response).to be_ok
    end

    it 'should return 404' do
      get '/wrong-path'
      expect(last_response.status).to eq(404)
      expect(last_response).to_not be_ok
    end

    it 'should download existing file' do
      get '/test'
      expect(last_response.body).to eq('content')
      expect(last_response).to be_ok
    end

    it 'should try to download gems.' do
      source = Gemirro::Source.new('test', 'http://rubygems.org')

      versions_fetcher = Gemirro::VersionsFetcher.new(source)
      versions_fetcher.should_receive(:fetch).once.and_return(true)

      gems_fetcher = Gemirro::VersionsFetcher.new(source)
      gems_fetcher.should_receive(:fetch).once.and_return(true)

      Struct.new('GemIndexer')
      gem_indexer = Struct::GemIndexer.new
      gem_indexer.should_receive(:update_gemspecs).once.and_return(true)
      gem_indexer.should_receive(:ui=).once.and_return(true)

      Gemirro.configuration.should_receive(:source).twice.and_return(source)
      Gemirro::GemsFetcher.should_receive(:new).once.and_return(gems_fetcher)
      Gemirro::VersionsFetcher.should_receive(:new)
        .once.and_return(versions_fetcher)
      Gemirro::Indexer.should_receive(:new).once.and_return(gem_indexer)
      ::Gem::SilentUI.should_receive(:new).once.and_return(true)

      get '/gems/gemirro-0.0.1.gem'
      expect(last_response).to_not be_ok
    end

    it 'should catch exceptions' do
      source = Gemirro::Source.new('test', 'http://rubygems.org')

      versions_fetcher = Gemirro::VersionsFetcher.new(source)
      versions_fetcher.should_receive(:fetch).once.and_return(true)

      gems_fetcher = Gemirro::VersionsFetcher.new(source)
      gems_fetcher.should_receive(:fetch).once.and_raise(
        StandardError, 'Not ok')

      gem_indexer = Struct::GemIndexer.new
      gem_indexer.should_receive(:update_gemspecs).once.and_return(true)
      gem_indexer.should_receive(:ui=).once.and_return(true)

      Gemirro.configuration.should_receive(:source).twice.and_return(source)
      Gemirro::GemsFetcher.should_receive(:new).once.and_return(gems_fetcher)
      Gemirro::VersionsFetcher.should_receive(:new)
        .once.and_return(versions_fetcher)
      Gemirro::Indexer.should_receive(:new).once.and_return(gem_indexer)
      ::Gem::SilentUI.should_receive(:new).once.and_return(true)

      get '/gems/gemirro-0.0.1.gem'
      expect(last_response).to_not be_ok
    end
  end
end
