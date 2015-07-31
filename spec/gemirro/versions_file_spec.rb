# -*- coding: utf-8 -*-
require 'spec_helper'
require 'zlib'
require 'gemirro/versions_file'

# VersionsFile tests
module Gemirro
  describe 'VersionsFile' do
    include FakeFS::SpecHelpers

    it 'should be initialized' do
      @versions_file = VersionsFile.new([
        ['gemirro', '0.0.1'],
        ['gemirro', '0.0.2']
      ])
      expect(@versions_file.versions).to eq([
        ['gemirro', '0.0.1'],
        ['gemirro', '0.0.2']
      ])
      expect(@versions_file.versions_hash).to eq(
        'gemirro' => [
          ['gemirro', '0.0.1'],
          ['gemirro', '0.0.2']
        ]
      )
    end

    it 'should load versions file' do
      spec = StringIO.new('w')
      w_gz = Zlib::GzipWriter.new(spec)
      w_gz.write(Marshal.dump([
        ['gemirro', '0.0.1'],
        ['gemirro', '0.0.2']
      ]))
      w_gz.close
      prerelease = StringIO.new('w')
      w_gz = Zlib::GzipWriter.new(prerelease)
      w_gz.write(Marshal.dump([
        ['gemirro', '0.0.1.alpha1'],
        ['gemirro', '0.0.2.alpha2']
      ]))
      w_gz.close

      result = VersionsFile.load(spec.string, prerelease.string)
      expect(result).to be_a(VersionsFile)

      expect(result.versions).to eq([
        ['gemirro', '0.0.1'],
        ['gemirro', '0.0.2'],
        ['gemirro', '0.0.1.alpha1'],
        ['gemirro', '0.0.2.alpha2']
      ])
      expect(result.versions_hash).to eq(
        'gemirro' => [
          ['gemirro', '0.0.1'],
          ['gemirro', '0.0.2'],
          ['gemirro', '0.0.1.alpha1'],
          ['gemirro', '0.0.2.alpha2']
        ]
      )
    end
  end
end
