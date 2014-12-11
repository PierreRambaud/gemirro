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
      skip if ::Gem::Version.new(RUBY_VERSION.dup) >= ::Gem::Version
                                                      .new('2.0.0')
    end

    it 'should install indicies' do
      dir = MirrorDirectory.new('./')
      dir.add_directory('gem_generate_index/quick/Marshal.4.8')
      ::Gem.configuration.should_receive(:really_verbose).once.and_return(true)

      indexer = Indexer.new('./')
      indexer.should_receive(:say)
        .once.with('Downloading index into production dir ./')
      indexer.quick_marshal_dir = 'gem_generate_index/quick/Marshal.4.8'
      indexer.dest_directory = './'
      indexer.directory = 'gem_generate_index'
      indexer.files = [
        'gem_generate_index/quick/Marshal.4.8',
        'gem_generate_index/specs.4.8.gz'
      ]

      FileUtils.should_receive(:mkdir_p).once.with('./quick', verbose: true)
      FileUtils.should_receive(:rm_rf)
        .once.with('gem_generate_index/specs.4.8.gz')
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

      files = indexer.install_indicies
      expect(files).to eq(['gem_generate_index/specs.4.8.gz'])
      expect(MirrorFile.new('specs.4.8.gz').read).to eq('content')
    end

    it 'should exit if there is no new gems' do
      dir = MirrorDirectory.new('./')
      dir.add_directory('gem_generate_index/gems')
      MirrorFile.new('./specs.4.8').write('')

      indexer = Indexer.new('./')
      indexer.should_receive(:make_temp_directories).and_return(true)

      expect { indexer.update_gemspecs }.to raise_error SystemExit
    end

    it 'should generate gemspecs files' do
      dir = MirrorDirectory.new('/')
      dir.add_directory('gems')
      dir.add_directory('quick')
      dir.add_directory('tmp')

      indexer = Indexer.new('/')

      dir.add_directory("#{indexer.directory.gsub(/^\//, '')}/gems")
      dir.add_directory("#{indexer.directory.gsub(/^\//, '')}/quick")
      MirrorFile.new('/specs.4.8').write('')
      MirrorFile.new("#{indexer.directory}/gems/gemirro-0.1.0.gem").write('')
      MirrorFile.new('gems/gemirro-0.1.0.gem').write('')
      MirrorFile.new("#{indexer.directory}/quick/gemirro-0.1.0.gemspec.rz")
        .write('test')

      indexer.should_receive(:gem_file_list)
        .and_return(['gems/gemirro-0.1.0.gem'])
      indexer.should_receive(:make_temp_directories).once.and_return(true)
      indexer.should_receive(:build_marshal_gemspecs).once.and_return([
        "#{indexer.directory}/quick/gemirro-0.1.0.gemspec.rz"])

      indexer.update_gemspecs
      expect(File.read('/quick/gemirro-0.1.0.gemspec.rz'))
        .to eq('test')
    end
  end
end
