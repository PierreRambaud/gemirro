require 'spec_helper'
require 'gemirro/source'
require 'gemirro/gem'
require 'gemirro/versions_file'
require 'gemirro/mirror_file'
require 'gemirro/gems_fetcher'

# GemsFetcher tests
module Gemirro
  describe 'GemsFetcher' do
    include FakeFS::SpecHelpers

    before(:each) do
      @source = Source.new('RubyGems', 'https://rubygems.org')
      @versions_file = VersionsFile.new(%(created_at: 2025-04-24T03:46:59Z\n---\nrack 3.0.0,3.0.1 d545a45462d63b1b4865bbb89a109366))
      @fetcher = GemsFetcher.new(@source, @versions_file)
      Gemirro.configuration.ignored_gems.clear
    end

    it 'should be initialized' do
      expect(@fetcher.source).to be(@source)
      expect(@fetcher.versions_file).to be(@versions_file)
    end

    it 'should test if gem exists' do
      Utils.configuration.destination = './'
      expect(@fetcher.gem_exists?('test')).to be_falsy
      MirrorDirectory.new('./').add_directory('gems')
      MirrorDirectory.new('./').add_directory('quick/Marshal.4.8')
      MirrorFile.new('gems/test').write('content')
      expect(@fetcher.gem_exists?('test')).to be_truthy
    end

    it 'should ignore gem' do
      allow(Utils.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.1.gem')
      expect(@fetcher.ignore_gem?('gemirro', '0.0.1', 'ruby')).to be_falsy
      Utils.configuration.ignore_gem('gemirro', '0.0.1', 'ruby')
      expect(@fetcher.ignore_gem?('gemirro', '0.0.1', 'ruby')).to be_truthy
      expect(@fetcher.ignore_gem?('gemirro', '0.0.1', 'java')).to be_falsy
    end

    it 'should log error when fetch gem failed' do
      allow(Utils.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.1.gem')
      gem = Gem.new('gemirro')
      version = ::Gem::Version.new('0.0.1')
      Utils.configuration.ignore_gem('gemirro', '0.0.1', 'ruby')
      allow(@source).to receive(:fetch_gem)
        .once.with('gemirro', version).and_raise(ArgumentError)
      allow(Utils.logger).to receive(:error)
        .once.with(/Failed to retrieve/)
      allow(Utils.logger).to receive(:debug)
        .once.with(/Adding (.*) to the list of ignored Gems/)

      expect(@fetcher.fetch_gem(gem, version)).to be_nil
      expect(@fetcher.ignore_gem?('gemirro', '0.0.1', 'ruby')).to be_truthy
    end

    it 'should fetch gem' do
      allow(Utils.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.1.gem')
      MirrorDirectory.new('./').add_directory('gems')
      gem = Gem.new('gemirro')
      version = ::Gem::Version.new('0.0.1')
      allow(@source).to receive(:fetch_gem)
        .with('gemirro-0.0.1.gem').and_return('gemirro')

      expect(@fetcher.fetch_gem(gem, version)).to eq('gemirro')
    end

    it 'should fetch latest gem' do
      allow(Utils.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.1.gem')
      MirrorDirectory.new('./').add_directory('gems')
      gem = Gem.new('gemirro', :latest)
      version = ::Gem::Version.new('0.0.1')
      allow(@source).to receive(:fetch_gem)
        .with('gemirro-0.0.1.gem').and_return('gemirro')

      expect(@fetcher.fetch_gem(gem, version)).to eq('gemirro')
    end

    it 'should fetch gemspec' do
      allow(Utils.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.1.gemspec.rz')
      MirrorDirectory.new('./').add_directory('quick/Marshal.4.8')
      gem = Gem.new('gemirro')
      gem.gemspec = true
      version = ::Gem::Version.new('0.0.1')
      allow(@source).to receive(:fetch_gemspec)
        .once.with('gemirro-0.0.1.gemspec.rz').and_return('gemirro')

      expect(@fetcher.fetch_gemspec(gem, version)).to eq('gemirro')
    end

    it 'should fetch latest gemspec' do
      allow(Utils.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.1.gemspec.rz')
      MirrorDirectory.new('./').add_directory('quick/Marshal.4.8')
      gem = Gem.new('gemirro', :latest)
      gem.gemspec = true
      version = ::Gem::Version.new('0.0.1')
      allow(@source).to receive(:fetch_gemspec)
        .once.with('gemirro-0.0.1.gemspec.rz').and_return('gemirro')

      expect(@fetcher.fetch_gemspec(gem, version)).to eq('gemirro')
    end

    it 'should not fetch gemspec if file exists' do
      allow(Utils.logger).to receive(:info)
        .once.with('Fetching gemirro-0.0.1.gemspec.rz')
      allow(@fetcher).to receive(:gemspec_exists?)
        .once.with('gemirro-0.0.1.gemspec.rz')
        .and_return(true)
      allow(Utils.logger).to receive(:debug)
        .once.with('Skipping gemirro-0.0.1.gemspec.rz')

      gem = Gem.new('gemirro')
      gem.gemspec = true
      version = ::Gem::Version.new('0.0.1')

      expect(@fetcher.fetch_gemspec(gem, version)).to be_nil
    end

    it 'should retrieve versions for specific gem' do
      gem = Gem.new('gemirro', '0.0.2')
      allow(@versions_file).to receive(:versions_for)
        .once.with('gemirro')
        .and_return([[::Gem::Version.new('0.0.1'), 'ruby'],
                     [::Gem::Version.new('0.0.2'), 'ruby']])
      expect(@fetcher.versions_for(gem)).to eq([[::Gem::Version.new('0.0.2'), 'ruby']])
    end

    it 'should fetch all gems and log debug if gem is not satisfied' do
      MirrorDirectory.new('./').add_directory('gems')
      gem = Gem.new('gemirro', '0.0.1')
      allow(gem.requirement).to receive(:satisfied_by?)
        .once.with(nil).and_return(false)
      @fetcher.source.gems << gem
      allow(Utils.logger).to receive(:debug)
        .once.with('Skipping gemirro-0.0.1.gem')
      expect(@fetcher.fetch).to eq([gem])
    end

    it 'should fetch all gems' do
      gem = Gem.new('gemirro', '0.0.2')
      @fetcher.source.gems << gem
      gemspec = Gem.new('gemirro', '0.0.1')
      gemspec.gemspec = true
      @fetcher.source.gems << gemspec

      allow(@fetcher).to receive(:fetch_gemspec)
        .once.with(gemspec, nil).and_return('gemfile')
      allow(@fetcher).to receive(:fetch_gem)
        .once.with(gem, nil).and_return('gemfile')

      allow(Utils.configuration.mirror_gems_directory).to receive(:add_file)
        .once.with('gemirro-0.0.2.gem', 'gemfile')
      allow(Utils.configuration.mirror_gemspecs_directory)
        .to receive(:add_file)
        .once.with('gemirro-0.0.1.gemspec.rz', 'gemfile')
      expect(@fetcher.fetch).to eq([gem, gemspec])
    end
  end
end
