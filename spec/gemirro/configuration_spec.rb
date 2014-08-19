# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/mirror_directory'
require 'gemirro/configuration'
require 'gemirro/source'

# Configuration tests
module Gemirro
  describe 'Configuration' do
    include FakeFS::SpecHelpers

    it 'should return configuration' do
      expect(Gemirro.configuration).to be_a Configuration
    end

    it 'should return logger' do
      expect(Gemirro.configuration.logger).to be_a Logger
    end

    it 'should return template directory' do
      FakeFS::FileSystem.clone(
        File.expand_path(
          './',
          Pathname.new(__FILE__).realpath
        )
      )
      expect(Configuration.template_directory).to eq(
        File.expand_path(
          '../../../template',
          Pathname.new(__FILE__).realpath
        )
      )
    end

    it 'should return default config file' do
      expect(Configuration.default_configuration_file).to eq('/config.rb')
    end

    it 'should return marshal identifier' do
      expect(Configuration.marshal_identifier).to match(/Marshal\.(\d+)\.(\d+)/)
    end

    it 'should return versions file' do
      expect(Configuration.versions_file).to match(/specs\.(\d+)\.(\d+).gz/)
    end

    it 'should return marshal file' do
      expect(Configuration.marshal_version).to eq(
        "#{Marshal::MAJOR_VERSION}.#{Marshal::MINOR_VERSION}"
      )
    end
  end

  describe 'Configuration::instance' do
    before(:each) do
      @config = Configuration.new
    end

    it 'return mirror directory' do
      @config.should_receive(:gems_directory).once.and_return('/tmp')
      expect(@config.mirror_directory).to be_a(MirrorDirectory)
      expect(@config.mirror_directory.path).to eq('/tmp')
    end

    it 'should return gems directory' do
      @config.should_receive(:destination).once.and_return('/tmp')
      expect(@config.gems_directory).to eq('/tmp/gems')
    end

    it 'should return ignored gems' do
      expect(@config.ignored_gems).to eq(Hash.new)
      expect(@config.ignore_gem?('rake', '1.0.0')).to be_falsy
      expect(@config.ignore_gem('rake', '1.0.0')).to eq(['1.0.0'])
      expect(@config.ignored_gems).to eq('rake' => ['1.0.0'])
      expect(@config.ignore_gem?('rake', '1.0.0')).to be_truthy
    end

    it 'should add and return source' do
      expect(@config.source).to eq(nil)
      result = @config.define_source('RubyGems', 'https://rubygems.org') do
      end
      expect(result).to be_a(Source)
      expect(result.gems).to eq([])
      expect(result.host).to eq('https://rubygems.org')
      expect(result.name).to eq('rubygems')
    end
  end
end
