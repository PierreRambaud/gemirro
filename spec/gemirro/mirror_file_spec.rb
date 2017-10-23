require 'spec_helper'
require 'gemirro/mirror_file'

# Mirror file tests
module Gemirro
  describe 'MirrorFile' do
    include FakeFS::SpecHelpers

    before(:each) do
      @mirror_file = MirrorFile.new('./test')
    end

    it 'should be initialized' do
      expect(@mirror_file.path).to eq('./test')
    end

    it 'should write and read content' do
      expect(@mirror_file.write('content')).to be_nil
      expect(@mirror_file.read).to eq('content')
    end
  end
end
