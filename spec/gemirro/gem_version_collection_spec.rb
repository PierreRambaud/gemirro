# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/gem_version_collection'
require 'gemirro/gem_version'

# Gem tests
module Gemirro
  describe 'GemVersionCollection' do
    it 'should be initialized' do
      collection = GemVersionCollection.new([['subzero',
                                              '0.0.1',
                                              'ruby'],
                                             GemVersion.new('alumina',
                                                            '0.0.1',
                                                            'ruby')])
      expect(collection.gems.first).to be_a(GemVersion)
      expect(collection.gems.last).to be_a(GemVersion)
      expect(collection.oldest).to be(collection.gems.first)
      expect(collection.newest).to be(collection.gems.last)
      expect(collection.size).to eq(2)
    end

    it 'should group and sort gems' do
      collection = GemVersionCollection.new([['subzero',
                                              '0.0.1',
                                              'ruby'],
                                             GemVersion.new('alumina',
                                                            '0.0.1',
                                                            'ruby')])
      expect(collection.by_name.first[0]).to eq('alumina')
      values = %w(alumina subzero)
      collection.by_name do |name, _version|
        expect(name).to eq(values.shift)
      end
    end

    it 'should find gem by name' do
      collection = GemVersionCollection.new([['subzero',
                                              '0.0.1',
                                              'ruby'],
                                             GemVersion.new('alumina',
                                                            '0.0.1',
                                                            'ruby'),
                                             GemVersion.new('alumina',
                                                            '0.0.2',
                                                            'ruby')])
      expect(collection.find_by_name('something')).to be_nil
      expect(collection.find_by_name('alumina').newest.name)
        .to eq('alumina')
      expect(collection.find_by_name('alumina').newest.version.to_s)
        .to eq('0.0.2')
    end
  end
end
