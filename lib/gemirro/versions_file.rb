module Gemirro
  ##
  # The VersionsFile class acts as a small Ruby wrapper around the RubyGems
  # file that contains all Gems and their associated versions.
  #
  # @!attribute [r] versions
  #  @return [Array]
  # @!attribute [r] versions_hash
  #  @return [Hash]
  #
  class VersionsFile
    attr_reader :versions, :versions_hash

    ##
    # Reads the versions file from the specified String.
    #
    # @param [String] spec_content
    # @param [String] prerelease_content
    # @return [Gemirro::VersionsFile]
    #
    def self.load(spec_content, prerelease_content)
      buffer = StringIO.new(spec_content)
      reader = Zlib::GzipReader.new(buffer)
      versions = Marshal.load(reader.read)

      buffer = StringIO.new(prerelease_content)
      reader = Zlib::GzipReader.new(buffer)
      versions.concat(Marshal.load(reader.read))

      instance = new(versions)

      reader.close

      instance
    end

    ##
    # @param [Array] versions
    #
    def initialize(versions)
      @versions      = versions
      @versions_hash = create_versions_hash
    end

    ##
    # Creates a Hash based on the Array containing all versions. This Hash is
    # used to more easily (and faster) iterate over all the gems/versions.
    #
    # @return [Hash]
    #
    def create_versions_hash
      hash = Hash.new { |h, k| h[k] = [] }

      versions.each do |version|
        hash[version[0]] << version
      end

      hash
    end

    ##
    # Returns an Array containing all the available versions for a Gem.
    #
    # @param [String] gem
    # @return [Array]
    #
    def versions_for(gem)
      versions_hash[gem].map { |version| [version[1], version[2]] }
    end
  end
end
