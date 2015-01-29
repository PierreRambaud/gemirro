# -*- coding: utf-8 -*-
require 'rack/test'
require 'gemirro/mirror_directory'
require 'gemirro/mirror_file'
require 'gemirro/gem_version_collection'

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
      @fake_logger = Logger.new(STDOUT)
      MirrorDirectory.new('/var/www/gemirro').add_directory('gems')
      MirrorDirectory.new('/').add_directory('tmp')
      MirrorFile.new('/var/www/gemirro/test').write('content')
      Gemirro.configuration.destination = '/var/www/gemirro'
      FakeFS::FileSystem.clone(Gemirro::Configuration.views_directory)
    end

    it 'should display index page' do
      allow(Logger).to receive(:new).twice.and_return(@fake_logger)
      allow(@fake_logger).to receive(:tap).and_return(nil)
        .and_yield(@fake_logger)

      get '/'
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
      allow(versions_fetcher).to receive(:fetch).once.and_return(true)

      gems_fetcher = Gemirro::VersionsFetcher.new(source)
      allow(gems_fetcher).to receive(:fetch).once.and_return(true)

      Struct.new('GemIndexer')
      gem_indexer = Struct::GemIndexer.new
      allow(gem_indexer).to receive(:update_gemspecs).once.and_return(true)
      allow(gem_indexer).to receive(:ui=).once.and_return(true)

      allow(Gemirro.configuration).to receive(:source).twice.and_return(source)
      allow(Gemirro::GemsFetcher).to receive(:new).once.and_return(gems_fetcher)
      allow(Gemirro::VersionsFetcher).to receive(:new)
        .once.and_return(versions_fetcher)
      allow(Gemirro::Indexer).to receive(:new).once.and_return(gem_indexer)
      allow(::Gem::SilentUI).to receive(:new).once.and_return(true)

      allow(Gemirro.configuration).to receive(:logger)
        .exactly(3).and_return(@fake_logger)
      allow(@fake_logger).to receive(:info).exactly(3)

      get '/gems/gemirro-0.0.1.gem'
      expect(last_response).to_not be_ok
      expect(last_response.status).to eq(404)

      MirrorFile.new('/var/www/gemirro/gems/gemirro-0.0.1.gem').write('content')
      get '/gems/gemirro-0.0.1.gem'
      expect(last_response).to be_ok
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('content')
    end

    it 'should catch exceptions' do
      source = Gemirro::Source.new('test', 'http://rubygems.org')

      versions_fetcher = Gemirro::VersionsFetcher.new(source)
      allow(versions_fetcher).to receive(:fetch).once.and_return(true)

      gems_fetcher = Gemirro::VersionsFetcher.new(source)
      allow(gems_fetcher).to receive(:fetch).once.and_raise(
        StandardError, 'Not ok')

      gem_indexer = Struct::GemIndexer.new
      allow(gem_indexer).to receive(:update_gemspecs).once.and_return(true)
      allow(gem_indexer).to receive(:ui=).once.and_return(true)

      allow(Gemirro.configuration).to receive(:source).twice.and_return(source)
      allow(Gemirro::GemsFetcher).to receive(:new).once.and_return(gems_fetcher)
      allow(Gemirro::VersionsFetcher).to receive(:new)
        .once.and_return(versions_fetcher)
      allow(Gemirro::Indexer).to receive(:new).once.and_return(gem_indexer)
      allow(::Gem::SilentUI).to receive(:new).once.and_return(true)

      allow(Gemirro.configuration).to receive(:logger)
        .exactly(3).and_return(@fake_logger)
      allow(@fake_logger).to receive(:info).exactly(2)
      allow(@fake_logger).to receive(:error)
      get '/gems/gemirro-0.0.1.gem'
      expect(last_response).to_not be_ok
    end
  end
end
