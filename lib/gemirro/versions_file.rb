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
    attr_reader :versions_string, :versions_hash

    ##
    # Reads the versions file from the specified String.
    #
    # @param [String] versions_content
    # @return [Gemirro::VersionsFile]
    #

    ##
    # @param [String] versions
    #
    def initialize(versions_string)
      unless versions_string.is_a? String
        throw "#{versions_string.class} is wrong format, expect String; #{versions_string.inspect}"
      end

      @versions_string = versions_string
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

      versions_string.each_line.with_index do |line, index|
        next if index < 2

        parts = line.split
        gem_name = parts[0]
        parts[-1]
        versions = parts[1..-2].collect { |x| x.split(',') }.flatten # All except first and last

        versions.each do |ver|
          version, platform =
            if ver.include?('-')
              ver.split('-', 2)
            else
              [ver, 'ruby']
            end
          hash[gem_name] << [gem_name, ::Gem::Version.new(version), platform]
        end
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
