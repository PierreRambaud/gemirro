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

    it 'should install indicies' do
      dir = MirrorDirectory.new('/tmp')
      dir.add_directory('test')
      dir.add_directory('gem_generate_index/quick/Marshal.4.8')
      allow(::Gem.configuration).to receive(:really_verbose)
        .once.and_return(true)

      indexer = Indexer.new('/tmp/test')
      indexer.quick_marshal_dir = '/tmp/gem_generate_index/quick/Marshal.4.8'
      indexer.dest_directory = '/tmp/test'
      indexer.directory = '/tmp/gem_generate_index'
      indexer.instance_variable_set('@specs_index',
                                    '/tmp/gem_generate_index/specs.4.8')
      indexer.files = [
        '/tmp/gem_generate_index/quick/Marshal.4.8',
        '/tmp/gem_generate_index/specs.4.8.gz',
        '/tmp/gem_generate_index/something.4.8.gz'
      ]

      allow(FileUtils).to receive(:mkdir_p)
        .once.with('/tmp/test/quick', verbose: true)
      allow(FileUtils).to receive(:rm_rf)
        .once.with('/tmp/gem_generate_index/something.4.8.gz')
      allow(FileUtils).to receive(:rm_rf)
        .once.with('/tmp/gem_generate_index/specs.4.8.gz')
      allow(FileUtils).to receive(:rm_rf)
        .once.with('/tmp/test/quick/Marshal.4.8', verbose: true)
      allow(FileUtils).to receive(:mv)
        .once
        .with('/tmp/gem_generate_index/quick/Marshal.4.8',
              '/tmp/test/quick/Marshal.4.8',
              verbose: true, force: true)

      source = Source.new('Rubygems', 'https://rubygems.org')
      allow(Gemirro.configuration).to receive(:source).and_return(source)

      Struct.new('HttpGet', :code, :body)
      wio = StringIO.new('w')
      w_gz = Zlib::GzipWriter.new(wio)
      w_gz.write(['content'])
      w_gz.close
      http_get = Struct::HttpGet.new(200, wio.string)
      allow(Marshal).to receive(:load).and_return(['content'])
      allow(Marshal).to receive(:dump).and_return(['content'])
      allow(Zlib::GzipWriter).to receive(:open)
        .once.with('/tmp/test/specs.4.8.gz.orig')
      allow(Zlib::GzipWriter).to receive(:open)
        .once.with('/tmp/test/specs.4.8.gz')
      allow(Http).to receive(:get)
        .with('https://rubygems.org/specs.4.8.gz').and_return(http_get)
      allow(Http).to receive(:get)
        .with('https://rubygems.org/something.4.8.gz').and_return(http_get)

      Struct.new('GzipReader', :read)
      gzip_reader = Struct::GzipReader.new(wio.string)
      allow(Zlib::GzipReader).to receive(:open)
        .once
        .with('/tmp/gem_generate_index/specs.4.8.gz')
        .and_return(gzip_reader)

      files = indexer.install_indicies
      expect(files).to eq(['/tmp/gem_generate_index/specs.4.8.gz',
                           '/tmp/gem_generate_index/something.4.8.gz'])
    end

    it 'should exit if there is no new gems' do
      dir = MirrorDirectory.new('./')
      dir.add_directory('gem_generate_index/gems')
      MirrorFile.new('./specs.4.8').write('')

      indexer = Indexer.new('./')
      allow(indexer).to receive(:make_temp_directories).and_return(true)
    end

    it 'should build indicies' do
      indexer = Indexer.new('/')
      dir = MirrorDirectory.new('/')
      dir.add_directory('gems')
      dir.add_directory('quick')
      dir.add_directory('tmp')
      dir.add_directory("#{indexer.directory.gsub(%r{^/}, '')}/gems")
      dir.add_directory("#{indexer.directory.gsub(%r{^/}, '')}/quick")

      MirrorFile.new('/specs.4.8').write('')
      MirrorFile.new("#{indexer.directory}/gems/gemirro-0.1.0.gem").write('')
      MirrorFile.new('gems/gemirro-0.1.0.gem').write('')
      MirrorFile.new("#{indexer.directory}/quick/gemirro-0.1.0.gemspec.rz")
        .write('test')

      allow(indexer).to receive(:gem_file_list)
        .and_return(['gems/gemirro-0.1.0.gem'])
      allow(indexer).to receive(:build_marshal_gemspecs).once.and_return([
        "#{indexer.directory}/quick/gemirro-0.1.0.gemspec.rz"])
      allow(indexer).to receive(:compress_indicies).once.and_return(true)

      indexer.build_indicies
    end
  end
end
