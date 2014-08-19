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
          filename  = gem.filename(version)
          satisfied = gem.requirement.satisfied_by?(version)
          name      = gem.name

          if gem_exists?(filename) || ignore_gem?(name, version) || !satisfied
            logger.debug("Skipping #{filename}")
            next
          end

          configuration.ignore_gem(gem.name, version)
          logger.info("Fetching #{filename}")
          gemfile = fetch_gem(gem, version)
          configuration.mirror_directory.add_file(filename, gemfile) if gemfile
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
    # Tries to download the Gemfile for the specified Gem and version.
    #
    # @param [Gemirro::Gem] gem
    # @param [Gem::Version] version
    # @return [String]
    #
    def fetch_gem(gem, version)
      data  = nil
      filename = gem.filename(version)

      begin
        data = @source.fetch_gem(gem.name, version)
      rescue => e
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
      configuration.mirror_directory.file_exists?(filename)
    end

    ##
    # @see Gemirro::Configuration#ignore_gem?
    #
    def ignore_gem?(*args)
      configuration.ignore_gem?(*args)
    end
  end
end
