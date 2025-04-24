# frozen_string_literal: true

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
    # @param [String] versions_content
    # @return [Gemirro::VersionsFile]
    #
    def self.load(versions_content)
      instance = new(versions_content)
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


      versions.each_line.with_index do |line, index|
        next if index < 2

        parts = line.split
        gem_name = parts[0]
        checksum = parts[-1]
        versions = parts[1..-2].collect{ |x| x.split(',') }.flatten  # All except first and last

        versions.each do |ver|
          version, platform =
            if ver.include?('-')
              ver.split('-', 2)
            else
              [ver, 'ruby']
            end

#throw versions

        #  versions.each do |version|

           # throw version
            hash[gem_name] << [gem_name, ::Gem::Version.new(version), platform]
          end
          #gems << Gemirro::GemVersion.new(gem_name, version, platform)
        #end
      end



      #versions.each do |version|
      #  hash[version[0]] << version
      #end

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
