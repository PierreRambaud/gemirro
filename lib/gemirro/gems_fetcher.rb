# -*- coding: utf-8 -*-
module Gemirro
  ##
  # The GemsFetcher class is responsible for downloading Gems from an external
  # source.
  #
  # @!attribute [r] source
  #  @return [Source]
  # @!attribute [r] versions_file
  #  @return [Gemirro::VersionsFile]
  #
  class GemsFetcher
    attr_reader :source, :versions_file

    ##
    # @param [Source] source
    # @param [Gemirro::VersionsFile] versions_file
    #
    def initialize(source, versions_file)
      @source        = source
      @versions_file = versions_file
    end

    ##
    # Fetches the Gems.
    #
    def fetch
      @source.gems.each do |gem|
        versions_for(gem).each do |version|
          if gem.gemspec?
            gemfile = fetch_gemspec(gem, version)
            configuration.mirror_gemspecs_directory
              .add_file(gem.gemspec_filename(version), gemfile) if gemfile
          else
            gemfile = fetch_gem(gem, version)
            configuration.mirror_gems_directory
              .add_file(gem.filename(version), gemfile) if gemfile
          end
        end
      end
    end

    ##
    # Returns an Array containing the versions that should be fetched for a
    # Gem.
    #
    # @param [Gemirro::Gem] gem
    # @return [Array]
    #
    def versions_for(gem)
      available       = @versions_file.versions_for(gem.name)
      versions        = gem.version? ? [gem.version] : available
      available_names = available.map(&:to_s)

      # Get rid of invalid versions. Due to Gem::Version having a custom ==
      # method, which treats "3.4" the same as "3.4.0" we'll have to compare
      # the versions as String instances.
      versions = versions.select do |version|
        available_names.include?(version.to_s)
      end

      versions = [available.last] if versions.empty?

      versions
    end

    ##
    # Tries to download gemspec from a given name and version
    #
    # @param [Gemirro::Gem] gem
    # @param [Gem::Version] version
    # @return [String]
    #
    def fetch_gemspec(gem, version)
      filename  = gem.gemspec_filename(version)
      satisfied = gem.requirement.satisfied_by?(version)

      if gemspec_exists?(filename) || !satisfied
        logger.debug("Skipping #{filename}")
        return
      end

      logger.info("Fetching #{filename}")
      fetch_from_source(gem, version, true)
    end

    ##
    # Tries to download the gem file from a given nam and version
    #
    # @param [Gemirro::Gem] gem
    # @param [Gem::Version] version
    # @return [String]
    #
    def fetch_gem(gem, version)
      filename = gem.filename(version)
      satisfied = gem.requirement.satisfied_by?(version)
      name = gem.name

      if gem_exists?(filename) || ignore_gem?(name, version) || !satisfied
        logger.debug("Skipping #{filename}")
        return
      end

      configuration.ignore_gem(gem.name, version)
      logger.info("Fetching #{filename}")

      fetch_from_source(gem, version)
    end

    ##
    #
    #
    # @param [Gemirro::Gem] gem
    # @param [Gem::Version] version
    # @return [String]
    #
    def fetch_from_source(gem, version, gemspec = false)
      data = nil
      begin
        data = @source.fetch_gem(gem.name, version) unless gemspec
        data = @source.fetch_gemspec(gem.name, version) if gemspec
      rescue => e
        filename = gem.filename(version)
        logger.error("Failed to retrieve #{filename}: #{e.message}")
        logger.debug("Adding #{filename} to the list of ignored Gems")

        configuration.ignore_gem(gem.name, version)
      end

      data
    end

    ##
    # @see Gemirro::Configuration#logger
    # @return [Logger]
    #
    def logger
      configuration.logger
    end

    ##
    # @see Gemirro.configuration
    #
    def configuration
      Gemirro.configuration
    end

    ##
    # Checks if a given Gem has already been downloaded.
    #
    # @param [String] filename
    # @return [TrueClass|FalseClass]
    #
    def gem_exists?(filename)
      configuration.mirror_gems_directory.file_exists?(filename)
    end

    ##
    # Checks if a given Gemspec has already been downloaded.
    #
    # @param [String] filename
    # @return [TrueClass|FalseClass]
    #
    def gemspec_exists?(filename)
      configuration.mirror_gemspecs_directory.file_exists?(filename)
    end

    ##
    # @see Gemirro::Configuration#ignore_gem?
    #
    def ignore_gem?(*args)
      configuration.ignore_gem?(*args)
    end
  end
end
