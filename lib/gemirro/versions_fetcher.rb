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
      VersionsFile.load(read_file(Configuration.versions_file),
                        read_file(Configuration.prerelease_versions_file, true))
    end

    ##
    # Read file if exists otherwise download its from source
    #
    # @param [String] file name
    # @param [TrueClass|FalseClass] prerelease Is prerelease or not
    #
    def read_file(file, prerelease = false)
      destination = Gemirro.configuration.destination
      file_dst = File.join(destination, file)
      unless File.exist?(file_dst)
        File.write(file_dst, @source.fetch_versions) unless prerelease
        File.write(file_dst, @source.fetch_prerelease_versions) if prerelease
      end

      File.read(file_dst)
    end
  end
end
