# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/gem'

# Gem tests
module Gemirro
  describe 'Gem' do
    before(:each) do
      @gem = Gem.new('gemirro', '0.0.1')
    end

    it 'should be initialized with string' do
      gem = Gem.new('gemirro', '0.0.1')
      expect(gem.name).to eq('gemirro')
      expect(gem.requirement).to eq(::Gem::Requirement.new(['= 0.0.1']))
    end

    it 'should be initialized with ::Gem::Requirement' do
      requirement = ::Gem::Requirement.new('0.0.1')
      gem = Gem.new('gemirro', requirement)
      expect(gem.name).to eq('gemirro')
      expect(gem.requirement).to be(requirement)
    end

    it 'should return version' do
      expect(@gem.version).to eq(::Gem::Version.new('0.0.1'))
    end

    it 'should check version' do
      expect(@gem.version?).to be_truthy
    end

    it 'should return gem filename' do
      expect(@gem.filename).to eq('gemirro-0.0.1.gem')
    end
  end
end
