# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/versions_fetcher'

# VersionsFetcher tests
module Gemirro
  describe 'VersionsFetcher' do
    before(:each) do
      @source = Source.new('RubyGems', 'https://rubygems.org')
      @fetcher = VersionsFetcher.new(@source)
    end

    it 'should be initialized' do
      expect(@fetcher.source).to be(@source)
    end

    it 'should fetch versions' do
      Gemirro.configuration.logger.should_receive(:info)
        .once.with("Updating #{@source.name} (#{@source.host})")
      @source.should_receive(:fetch_versions).once.and_return([])
      VersionsFile.should_receive(:load).with([])
      expect(@fetcher.fetch).to be_nil
    end
  end
end
