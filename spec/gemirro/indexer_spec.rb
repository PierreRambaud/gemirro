# -*- coding: utf-8 -*-
require 'spec_helper'
require 'rubygems/indexer'
require 'gemirro/source'
require 'gemirro/indexer'
require 'gemirro/mirror_file'
require 'gemirro/mirror_directory'

# Indexer tests
module Gemirro
  describe 'Indexer' do
    include FakeFS::SpecHelpers

    before(:each) do
      skip if ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('2.0.0')
    end

    it 'should install indicies' do
      dir = MirrorDirectory.new('./')
      dir.add_directory('gem_generate_index/quick/Marshal.4.8')
      ::Gem.configuration.should_receive(:really_verbose).once.and_return(true)

      @indexer = Indexer.new('./')
      @indexer.should_receive(:say)
        .once.with('Downloading index into production dir ./')
      @indexer.quick_marshal_dir = 'gem_generate_index/quick/Marshal.4.8'
      @indexer.dest_directory = './'
      @indexer.directory = 'gem_generate_index'
      @indexer.files = [
        'gem_generate_index/quick/Marshal.4.8',
        'gem_generate_index/specs.4.8.gz'
      ]

      FileUtils.should_receive(:mkdir_p).once.with('./quick', verbose: true)
      FileUtils.should_receive(:rm_rf)
        .once.with('./quick/Marshal.4.8', verbose: true)
      FileUtils.should_receive(:mv)
        .once
        .with('gem_generate_index/quick/Marshal.4.8', './quick/Marshal.4.8',
              verbose: true, force: true)
      source = Source.new('Rubygems', 'https://rubygems.org')
      Gemirro.configuration.should_receive(:source).and_return(source)
      Struct.new('HttpGet', :code, :body)
      http_get = Struct::HttpGet.new(200, 'content')
      Http.should_receive(:get)
        .with('https://rubygems.org/specs.4.8.gz').and_return(http_get)

      files = @indexer.install_indicies
      expect(files).to eq(['specs.4.8.gz'])
      files.each do |f|
        expect(MirrorFile.new(f).read).to eq('content')
      end
    end
  end
end
