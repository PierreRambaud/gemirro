# -*- coding: utf-8 -*-

module Gemirro
  ##
  # The Utils class is responsible for executing specific traitments
  # that are located at least on two other files
  #
  # @!attribute [r] client
  #  @return [HTTPClient]
  #
  class Utils
    attr_reader :cache

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
      gems = []
      specs_files_paths(orig).pmap do |specs_file_path|
        next unless File.exist?(specs_file_path)
        spec_gems = cache.cache(File.basename(specs_file_path)) do
          Marshal.load(Zlib::GzipReader.open(specs_file_path).read)
        end
        gems.concat(spec_gems)
      end

      collection = GemVersionCollection.new(gems)
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
  end
end
