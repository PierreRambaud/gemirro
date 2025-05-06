# frozen_string_literal: true

require 'gemirro/gem_version'

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

    URI_REGEXP = /^(.*)-(\d+(?:\.\d+){1,4}.*?)(?:-(x86-(?:(?:mswin|mingw)(?:32|64)).*?|java))?\.(gem(?:spec\.rz)?)$/
    GEMSPEC_TYPE = 'gemspec.rz'
    GEM_TYPE = 'gem'

    ##
    # Generate Gems collection from Marshal dump - always the .local file
    #
    # @return [Gemirro::GemVersionCollection]
    #
    def self.gems_collection
      @gems_collection ||= { files: {}, values: nil }

      file_paths =
        Dir.glob(File.join(
                   Gemirro.configuration.destination,
                   'versions.*.*.list'
                 ))

      has_file_changed =
        @gems_collection[:files] != file_paths.each_with_object({}) do |f, r|
          r[f] = File.mtime(f) if File.exist?(f)
        end

      # Return result if no file changed
      return @gems_collection[:values] if !has_file_changed && !@gems_collection[:values].nil?

      gems = []

      CompactIndex::VersionsFile.new(file_paths.last).contents.each_line.with_index do |line, index|
        next if index < 2

        gem_name = line.split[0]
        versions = line.split[1..-2].collect { |x| x.split(',') }.flatten # All except first and last

        versions.each do |ver|
          version, platform =
            if ver.include?('-')
              ver.split('-', 2)
            else
              [ver, 'ruby']
            end

          gems << Gemirro::GemVersion.new(gem_name, version, platform)
        end
      end

      @gems_collection[:values] = GemVersionCollection.new(gems)
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
    def self.spec_for(gemname, version, platform)
      gem = Utils.stored_gem(gemname, version.to_s, platform)

      spec_file =
        File.join(
          configuration.destination,
          'quick',
          Gemirro::Configuration.marshal_identifier,
          gem.gemspec_filename
        )

      fetch_gem(spec_file) unless File.exist?(spec_file)

      # this is a separate action
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
    # Update indexes files
    #
    # @return [Indexer]
    #
    def self.update_indexes
      indexer = Gemirro::Indexer.new
      indexer.only_origin = true
      indexer.ui = ::Gem::SilentUI.new

      Utils.logger.info('Generating indexes')
      indexer.update_index
    rescue SystemExit => e
      Utils.logger.info(e.message)
    end
  end
end
