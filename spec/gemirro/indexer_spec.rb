# -*- coding: utf-8 -*-
require 'spec_helper'
require 'rubygems/indexer'
require 'tempfile'
require 'gemirro/source'
require 'gemirro/indexer'
require 'gemirro/mirror_file'
require 'gemirro/mirror_directory'

# Indexer tests
module Gemirro
  describe 'Indexer' do
    include FakeFS::SpecHelpers

    before(:each) do
      allow_any_instance_of(Logger).to receive(:info)
      allow_any_instance_of(Logger).to receive(:debug)
      allow_any_instance_of(Logger).to receive(:warn)
    end

    it 'should download from source' do
      source = Source.new('Rubygems', 'https://rubygems.org')
      allow(Gemirro.configuration).to receive(:source).and_return(source)

      dir = MirrorDirectory.new('/tmp')
      dir.add_directory('test')
      indexer = Indexer.new('/tmp/test')

      Struct.new('HttpGet', :code, :body)
      http_get = Struct::HttpGet.new(200, 'bad')
      allow(Http).to receive(:get).once.and_return(http_get)

      expect(indexer.download_from_source('something'))
        .to eq('bad')
    end

    it 'should install indices' do
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
      allow(FileUtils).to receive(:mkdir_p).and_return(true)
      allow(FileUtils).to receive(:rm_f).and_return(true)
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

      allow(FileUtils).to receive(:mv)

      source = Source.new('Rubygems', 'https://rubygems.org')
      allow(Gemirro.configuration).to receive(:source).and_return(source)

      wio = StringIO.new('w')
      w_gz = Zlib::GzipWriter.new(wio)
      w_gz.write(['content'])
      w_gz.close
      allow(indexer).to receive(:download_from_source).and_return(wio.string)

      allow(Marshal).to receive(:load).and_return(['content'])
      allow(Marshal).to receive(:dump).and_return(['content'])

      Struct.new('GzipReader', :read)
      gzip_reader = Struct::GzipReader.new(wio.string)
      allow(Zlib::GzipReader).to receive(:open)
        .once
        .with('/tmp/gem_generate_index/specs.4.8.gz')
        .and_return(gzip_reader)

      files = indexer.install_indices
      expect(files).to eq(['/tmp/gem_generate_index/specs.4.8.gz',
                           '/tmp/gem_generate_index/something.4.8.gz'])
    end

    it 'should build indices' do
      indexer = Indexer.new('/')
      dir = MirrorDirectory.new('/')
      dir.add_directory('gems')
      dir.add_directory('quick')
      dir.add_directory('tmp')
      dir.add_directory("#{indexer.directory.gsub(%r{^/}, '')}/gems")
      dir.add_directory("#{indexer.directory.gsub(%r{^/}, '')}/quick")

      fixtures_dir = File.dirname(__FILE__) + '/../fixtures'
      FakeFS::FileSystem
        .clone("#{fixtures_dir}/gems/gemirro-0.0.1.gem",
               "#{indexer.directory}/gems/gemirro-0.0.1.gem")
      FakeFS::FileSystem
        .clone("#{fixtures_dir}/gems/gemirro-0.0.1.gem",
               '/gems/gemirro-0.0.1.gem')
      FakeFS::FileSystem
        .clone("#{fixtures_dir}/gems/gemirro-0.0.1.gem",
               '/gems/gemirral-0.0.1.gem') # Skipping misnamed
      FakeFS::FileSystem
        .clone("#{fixtures_dir}/quick/gemirro-0.0.1.gemspec.rz",
               "#{indexer.directory}/quick/gemirro-0.0.1.gemspec.rz")

      MirrorFile.new('gems/gemirro-0.0.2.gem').write('') # Empty file
      MirrorFile.new('gems/gemirro-0.0.3.gem').write('Error') # Empty file
      MirrorFile.new('/specs.4.8').write('')

      allow(indexer).to receive(:gem_file_list)
        .and_return(['gems/gemirro-0.0.1.gem',
                     'gems/gemirro-0.0.2.gem',
                     'gems/gemirro-0.0.3.gem',
                     'gems/gemirral-0.0.1.gem'])

      allow(indexer).to receive(:build_marshal_gemspecs).once
        .and_return(["#{indexer.directory}/quick/gemirro-0.0.1.gemspec.rz"])

      allow(indexer).to receive(:compress_indicies).once.and_return(true)
      allow(indexer).to receive(:compress_indices).once.and_return(true)

      indexer.build_indices
    end

    it 'should update index and exit ruby gems' do
      indexer = Indexer.new('/')
      MirrorDirectory.new('/')
      MirrorFile.new('/specs.4.8').write('')
      expect { indexer.update_index }.to raise_error(::Gem::SystemExitException)
    end

    it 'should update index' do
      dir = MirrorDirectory.new('/tmp')
      dir.add_directory('gem_generate_index/quick/Marshal.4.8')
      dir.add_directory('test/gems')
      dir.add_directory('test/quick')

      indexer = Indexer.new('/tmp/test')
      indexer.quick_marshal_dir = '/tmp/gem_generate_index/quick/Marshal.4.8'
      indexer.dest_directory = '/tmp/test'
      indexer.directory = '/tmp/gem_generate_index'
      indexer.instance_variable_set('@specs_index',
                                    '/tmp/gem_generate_index/specs.4.8')

      MirrorFile.new("#{indexer.directory}/specs.4.8.gz").write('')
      MirrorFile.new("#{indexer.directory}/specs.4.8").write('')
      MirrorFile.new("#{indexer.dest_directory}/specs.4.8").write('')
      File.utime(Time.at(0), Time.at(0), "#{indexer.dest_directory}/specs.4.8")

      fixtures_dir = File.dirname(__FILE__) + '/../fixtures'
      FakeFS::FileSystem
        .clone("#{fixtures_dir}/gems/gemirro-0.0.1.gem",
               "#{indexer.dest_directory}/gems/gemirro-0.0.1.gem")
      FakeFS::FileSystem
        .clone("#{fixtures_dir}/quick/gemirro-0.0.1.gemspec.rz",
               "#{indexer.directory}/quick/gemirro-0.0.1.gemspec.rz")

      allow(indexer).to receive(:make_temp_directories)
      allow(indexer).to receive(:update_specs_index)
      allow(indexer).to receive(:compress_indicies)
      allow(indexer).to receive(:compress_indices)
      allow(indexer).to receive(:build_zlib_file)
      # rubocop:disable Metrics/LineLength
      allow(indexer).to receive(:build_marshal_gemspecs).once.and_return(["#{indexer.directory}/quick/gemirro-0.0.1.gemspec.rz"])
      # rubocop:enable Metrics/LineLength

      allow(Marshal).to receive(:load).and_return(['content'])
      allow(Marshal).to receive(:dump).and_return(['content'])
      allow(FileUtils).to receive(:mv)
      allow(File).to receive(:utime)

      indexer.update_index
    end
  end
end
