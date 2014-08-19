# -*- coding: utf-8 -*-
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
      Gemirro.configuration.logger.info(
        "Updating #{source.name} (#{source.host})"
      )

      VersionsFile.load(source.fetch_versions)
    end
  end
end
