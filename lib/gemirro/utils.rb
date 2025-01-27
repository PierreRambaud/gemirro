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
    attr_reader(
      :versions_fetcher,
      :gems_fetcher,
      :gems_collection,
      :stored_gems
    )

    # rubocop:disable Layout/LineLength
    URI_REGEXP = /^(.*)-(\d+(?:\.\d+){1,4}.*?)(?:-(x86-(?:(?:mswin|mingw)(?:32|64)).*?|java))?\.(gem(?:spec\.rz)?)$/.freeze
    # rubocop:enable Layout/LineLength

    GEMSPEC_TYPE = 'gemspec.rz'
    GEM_TYPE = 'gem'

    ##
    # Generate Gems collection from Marshal dump
    #
    # @param [TrueClass|FalseClass] orig Fetch orig files
    # @return [Gemirro::GemVersionCollection]
    #
    def self.gems_collection(orig = true)
      @gems_collection = {} if @gems_collection.nil?

      data = @gems_collection[orig ? 1 : 0]
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
        File.join(
          configuration.destination,
          [
            specs_file_type,
            marshal_version,
            "gz#{orig ? '.orig' : ''}"
          ].join('.')
        )
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
      @versions_fetcher ||= Gemirro::VersionsFetcher.new(configuration.source).fetch
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

    ##
    # Return gem specification from gemname and version
    #
    # @param [String] gemname
    # @param [String] version
    # @return [::Gem::Specification]
    #
    def self.spec_for(gemname, version, platform = 'ruby')
      gem = Utils.stored_gem(gemname, version.to_s, platform)

      spec_file =
        File.join(
          'quick',
          Gemirro::Configuration.marshal_identifier,
          gem.gemspec_filename
        )

      fetch_gem(spec_file) unless File.exist?(spec_file)

      return unless File.exist?(spec_file)

      File.open(spec_file, 'r') do |uz_file|
        uz_file.binmode
        inflater = Zlib::Inflate.new
        begin
          inflate_data = inflater.inflate(uz_file.read)
        ensure
          inflater.finish
          inflater.close
        end
        Marshal.load(inflate_data)
      end
    end

    ##
    # Try to fetch gem and download its if it's possible, and
    # build and install indicies.
    #
    # @param [String] resource
    # @return [Indexer]
    #
    def self.fetch_gem(resource)
      return unless Utils.configuration.fetch_gem

      name = File.basename(resource)
      result = name.match(URI_REGEXP)
      return unless result

      gem_name, gem_version, gem_platform, gem_type = result.captures
      return unless gem_name && gem_version

      begin
        gem = Utils.stored_gem(gem_name, gem_version, gem_platform)
        gem.gemspec = true if gem_type == GEMSPEC_TYPE

        return if Utils.gems_fetcher.gem_exists?(gem.filename(gem_version)) && gem_type == GEM_TYPE
        return if Utils.gems_fetcher.gemspec_exists?(gem.gemspec_filename(gem_version)) && gem_type == GEMSPEC_TYPE

        Utils.logger.info("Try to download #{gem_name} with version #{gem_version}")
        Utils.gems_fetcher.source.gems.clear
        Utils.gems_fetcher.source.gems.push(gem)
        Utils.gems_fetcher.fetch

        update_indexes if Utils.configuration.update_on_fetch
      rescue StandardError => e
        Utils.logger.error(e)
      end
    end

    ##
    # Return gems list from query params
    #
    # @return [Array]
    #
    def self.query_gems_list(query_gems)
      Utils.gems_collection(false) # load collection
      gems = Parallel.map(query_gems, in_threads: Utils.configuration.update_thread_count) do |query_gem|
        gem_dependencies(query_gem)
      end

      gems.flatten.compact.reject(&:empty?)
    end

    ##
    # Update indexes files
    #
    # @return [Indexer]
    #
    def self.update_indexes
      indexer = Gemirro::Indexer.new(Utils.configuration.destination)
      indexer.only_origin = true
      indexer.ui = ::Gem::SilentUI.new

      Utils.logger.info('Generating indexes')
      indexer.update_index
    #      indexer.updated_gems.each do |gem|
    #        Utils.cache.flush_key(File.basename(gem))
    #      end
    rescue SystemExit => e
      Utils.logger.info(e.message)
    end
  end
end
