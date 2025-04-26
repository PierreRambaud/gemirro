# frozen_string_literal: true

module Gemirro
  ##
  # The VersionsFetcher class is used for retrieving the file that contains all
  # registered Gems and their versions.
  #
  # @!attribute [r] source
  # @return [Source]
  #
  class VersionsFetcher
    attr_reader :source

    ##
    # @param [Source] source
    #
    def initialize(source)
      @source = source
    end

    ##
    # @return [Gemirro::VersionsFile]
    #
    def fetch
      VersionsFile.new(
        read_file(Gemirro.configuration.versions_file)
      )
    end

    ##
    # Read file if exists otherwise download its from source
    #
    # @param [String] file name
    #
    def read_file(file)
      unless File.exist?(file)
        throw 'No source defined' unless @source

        File.write(file, @source.fetch_versions)
      end

      File.read(file)
    end
  end
end
