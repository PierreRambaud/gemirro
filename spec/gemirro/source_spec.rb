# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/http'
require 'gemirro/source'

# Source tests
module Gemirro
  describe 'Source' do
    before(:each) do
      @source = Source.new('RubyGems', 'https://rubygems.org')
    end

    it 'should be initialized' do
      expect(@source.name).to eq('rubygems')
      expect(@source.host).to eq('https://rubygems.org')
      expect(@source.gems).to eq([])
    end

    it 'should fetch versions' do
      Struct.new('FetchVersions', :body)
      result = Struct::FetchVersions.new(true)
      Http.should_receive(:get).once.with(
        "https://rubygems.org/#{Configuration.versions_file}"
      ).and_return(result)
      expect(@source.fetch_versions).to be_truthy
    end

    it 'should fetch gem' do
      Struct.new('FetchGem', :body)
      result = Struct::FetchGem.new(true)
      Http.should_receive(:get).once.with(
        'https://rubygems.org/gems/gemirro-0.0.1.gem').and_return(result)
      expect(@source.fetch_gem('gemirro', '0.0.1')).to be_truthy
    end

    it 'should add gems' do
      expect(@source.gems).to eq([])
      @source.gem('gemirro')
      result = @source.gems
      expect(result[0].name).to eq('gemirro')
      expect(result[0].requirement).to be_a(::Gem::Requirement)
    end
  end
end
