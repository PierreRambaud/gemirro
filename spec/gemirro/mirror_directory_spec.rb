# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/mirror_directory'
require 'gemirro/mirror_file'

# MirrorDirectory tests
module Gemirro
  describe 'MirrorDirectory' do
    include FakeFS::SpecHelpers

    before(:each) do
      @mirror_directory = MirrorDirectory.new('./')
    end

    it 'should be initialized' do
      expect(@mirror_directory.path).to eq('./')
    end

    it 'should add directory' do
      expect(@mirror_directory.add_directory('test/test2'))
        .to be_a(MirrorDirectory)
      expect(File.directory?('./test/test2')).to be_truthy
    end

    it 'should add file' do
      result = @mirror_directory.add_file('file', 'content')
      expect(result).to be_a(MirrorFile)
      expect(result.read).to eq('content')
    end

    it 'should test if file exists' do
      expect(@mirror_directory.file_exists?('test')).to be_falsy
      @mirror_directory.add_file('test', 'content')
      expect(@mirror_directory.file_exists?('test')).to be_truthy
    end
  end
end
