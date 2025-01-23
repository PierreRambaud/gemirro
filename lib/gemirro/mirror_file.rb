# frozen_string_literal: true

module Gemirro
  ##
  # Similar to {Gemirro::MirrorDirectory} the MirrorFile class is used to
  # make it easier to read and write data in a directory that mirrors data from
  # an external source.
  #
  # @!attribute [r] path
  #  @return [String]
  #
  class MirrorFile
    attr_reader :path

    ##
    # @param [String] path
    #
    def initialize(path)
      @path = path
    end

    ##
    # Writes the specified content to the current file. Existing files are
    # overwritten.
    #
    # @param [String] content
    #
    def write(content)
      FileUtils.mkdir_p(File.dirname(@path))
      handle = File.open(@path, 'w')

      handle.write(content)
      handle.close
    end

    ##
    # Reads the content of the current file.
    #
    # @return [String]
    #
    def read
      handle  = File.open(@path, 'r')
      content = handle.read

      handle.close

      content
    end
  end
end
