# frozen_string_literal: true

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
                :gems_collection,
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
      @gems_collection = {} if @gems_collection.nil?

      is_orig = orig ? 1 : 0
      data = @gems_collection[is_orig]
      data = { files: {}, values: nil } if data.nil?

      file_paths = specs_files_paths(orig)
      has_file_changed = false
      Parallel.map(file_paths, in_threads: Utils.configuration.update_thread_count) do |file_path|
        next if data[:files].key?(file_path) &&
                data[:files][file_path] == File.mtime(file_path)

        has_file_changed = true
      end

      # Return result if no file changed
      return data[:values] if !has_file_changed && !data[:values].nil?

      gems = []
      Parallel.map(file_paths, in_threads: Utils.configuration.update_thread_count) do |file_path|
        next unless File.exist?(file_path)

        gems.concat(Marshal.load(Zlib::GzipReader.open(file_path).read))
        data[:files][file_path] = File.mtime(file_path)
      end

      collection = GemVersionCollection.new(gems)
      data[:values] = collection

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
      Parallel.map(specs_file_types, in_threads: Utils.configuration.update_thread_count) do |specs_file_type|
        File.join(configuration.destination,
                  [specs_file_type,
                   marshal_version,
                   "gz#{orig ? '.orig' : ''}"].join('.'))
      end
    end

    ##
    # Return specs fils types
    #
    # @return [Array]
    #
    def self.specs_file_types
      %i[specs prerelease_specs]
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
      @gems_fetcher ||= Gemirro::GemsFetcher
                        .new(configuration.source, versions_fetcher)
    end

    ##
    # Try to cache gem classes
    #
    # @param [String] gem_name Gem name
    # @return [Gem]
    #
    def self.stored_gem(gem_name, gem_version, platform = 'ruby')
      platform = 'ruby' if platform.nil?
      @stored_gems ||= {}
      @stored_gems[gem_name] = {} unless @stored_gems.key?(gem_name)
      @stored_gems[gem_name][gem_version] = {} unless @stored_gems[gem_name].key?(gem_version)
      unless @stored_gems[gem_name][gem_version].key?(platform)
        @stored_gems[gem_name][gem_version][platform] ||= Gem.new(gem_name, gem_version, platform)
      end

      @stored_gems[gem_name][gem_version][platform]
    end
  end
end
