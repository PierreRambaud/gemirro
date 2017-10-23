require 'spec_helper'
require 'gemirro/gem_version'

# Gem tests
module Gemirro
  describe 'GemVersion' do
    it 'should be initialized' do
      gem = GemVersion.new('gemirro',
                           '0.0.1',
                           'ruby')
      expect(gem.name).to eq('gemirro')
      expect(gem.number).to eq('0.0.1')
      expect(gem.platform).to eq('ruby')
      expect(gem.ruby?).to be_truthy
      expect(gem.version).to be_a(::Gem::Version)
      expect(gem.gemfile_name).to eq('gemirro-0.0.1')
    end

    it 'should be initialized with other platform' do
      gem = GemVersion.new('gemirro',
                           '0.0.1',
                           'jruby')
      expect(gem.name).to eq('gemirro')
      expect(gem.number).to eq('0.0.1')
      expect(gem.platform).to eq('jruby')
      expect(gem.ruby?).to be_falsy
      expect(gem.version).to be_a(::Gem::Version)
      expect(gem.gemfile_name).to eq('gemirro-0.0.1-jruby')
    end

    it 'should compare with an other gem' do
      first_gem = GemVersion.new('gemirro',
                                 '0.0.1',
                                 'ruby')
      second_gem = GemVersion.new('gemirro',
                                  '0.0.2',
                                  'ruby')
      third_gem = GemVersion.new('gemirro',
                                 '0.0.1',
                                 'ruby')
      expect(first_gem < second_gem).to eq(true)
      expect(second_gem < first_gem).to eq(false)
      expect(first_gem == third_gem).to eq(true)
      expect(first_gem != second_gem).to eq(true)
    end
  end
end
