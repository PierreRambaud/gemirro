# -*- coding: utf-8 -*-

module Gemirro
  ##
  # The Utils class is responsible for executing specific traitments
  # that are located at least on two other files
  #
  # @!attribute [r] client
  #  @return [HTTPClient]
  # @!attribute [r] versions_fetcher
  #  @return [VersionsFetcher]
  # @!attribute [r] gems_fetcher
  #  @return [Gemirro::GemsFetcher]
  #
  class Utils
    attr_reader(:cache,
                :versions_fetcher,
                :gems_fetcher,
                :gems_orig_collection,
                :gems_source_collection,
                :stored_gems)
    ##
    # Cache class to store marshal and data into files
    #
    # @return [Gemirro::Cache]
    #
    def self.cache
      @cache ||= Gemirro::Cache
                 .new(File.join(configuration.destination, '.cache'))
    end

    ##
    # Generate Gems collection from Marshal dump
    #
    # @param [TrueClass|FalseClass] orig Fetch orig files
    # @return [Gemirro::GemVersionCollection]
    #
    def self.gems_collection(orig = true)
      return @gems_orig_collection if orig && !@gems_orig_collection.nil?
      return @gems_source_collection if !orig && !@gems_source_collection.nil?

      gems = []
      specs_files_paths(orig).pmap do |specs_file_path|
        next unless File.exist?(specs_file_path)
        spec_gems = cache.cache(File.basename(specs_file_path)) do
          Marshal.load(Zlib::GzipReader.open(specs_file_path).read)
        end
        gems.concat(spec_gems)
      end

      collection = GemVersionCollection.new(gems)
      @gems_source_collection = collection unless orig
      @gems_orig_collection = collection if orig

      collection
    end

    ##
    # Return specs fils paths
    #
    # @param [TrueClass|FalseClass] orig Fetch orig files
    # @return [Array]
    #
    def self.specs_files_paths(orig = true)
      marshal_version = Gemirro::Configuration.marshal_version
      specs_file_types.pmap do |specs_file_type|
        File.join(configuration.destination,
                  [specs_file_type,
                   marshal_version,
                   'gz' + (orig ? '.orig' : '')
                  ].join('.'))
      end
    end

    ##
    # Return specs fils types
    #
    # @return [Array]
    #
    def self.specs_file_types
      [:specs, :prerelease_specs]
    end

    ##
    # @see Gemirro::Configuration#logger
    # @return [Logger]
    #
    def self.logger
      configuration.logger
    end

    ##
    # @see Gemirro.configuration
    #
    def self.configuration
      Gemirro.configuration
    end

    ##
    # @see Gemirro::VersionsFetcher.fetch
    #
    def self.versions_fetcher
      @versions_fetcher ||= Gemirro::VersionsFetcher
                            .new(configuration.source).fetch
    end

    ##
    # @return [Gemirro::GemsFetcher]
    #
    def self.gems_fetcher
      @gems_fetcher ||= Gemirro::GemsFetcher.new(
        configuration.source, versions_fetcher)
    end

    ##
    # Try to cache gem classes
    #
    # @param [String] gem_name Gem name
    # @return [Gem]
    #
    def self.stored_gem(gem_name, gem_version, platform = 'ruby')
      @stored_gems ||= {}
      # rubocop:disable Metrics/LineLength
      @stored_gems[gem_name] = {} unless @stored_gems.key?(gem_name)
      @stored_gems[gem_name][gem_version] = {} unless @stored_gems[gem_name].key?(gem_version)
      @stored_gems[gem_name][gem_version][platform] ||= Gem.new(gem_name, gem_version, platform) unless @stored_gems[gem_name][gem_version].key?(platform)
      # rubocop:enable Metrics/LineLength

      @stored_gems[gem_name][gem_version][platform]
    end
  end
end
