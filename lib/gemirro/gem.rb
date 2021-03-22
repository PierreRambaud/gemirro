# frozen_string_literal: true

module Gemirro
  ##
  # The Gem class contains data about a Gem such as the name, requirement as
  # well as providing some methods to more easily extract the specific version
  # number.
  #
  # @!attribute [r] name
  #  @return [String]
  # @!attribute [r] requirement
  #  @return [Gem::Requirement]
  # @!attribute [r] version
  #  @return [Gem::Version]
  #
  class Gem
    attr_reader :name, :requirement
    attr_accessor :gemspec, :platform

    ONLY_LATEST = %i[latest newest].freeze

    ##
    # Returns a `Gem::Version` instance based on the specified requirement.
    #
    # @param [Gem::Requirement] requirement
    # @return [Gem::Version]
    #
    def self.version_for(requirement)
      ::Gem::Version.new(requirement.requirements.max.last.version)
    end

    ##
    # @param [String] name
    # @param [Gem::Requirement|String] requirement
    #
    def initialize(name, requirement = nil, platform = 'ruby')
      requirement ||= ::Gem::Requirement.default

      requirement = ::Gem::Requirement.new(requirement) if requirement.is_a?(String)

      @name = name
      @requirement = requirement
      @platform = platform
    end

    ##
    # Returns the version
    #
    # @return [Gem::Version]
    #
    def version
      @version ||= self.class.version_for(requirement)
    end

    ##
    # Define if version exists
    #
    # @return [TrueClass|FalseClass]
    #
    def version?
      version && !version.segments.reject(&:zero?).empty?
    end

    ##
    # Define if version exists
    #
    # @return [TrueClass|FalseClass]
    #
    def only_latest?
      @requirement.is_a?(Symbol) && ONLY_LATEST.include?(@requirement)
    end

    ##
    # Is gemspec
    #
    # @return [TrueClass|FalseClass]
    #
    def gemspec?
      @gemspec == true
    end

    ##
    # Returns the filename of the gem file.
    #
    # @param [String] gem_version
    # @return [String]
    #
    def filename(gem_version = nil)
      gem_version ||= version.to_s
      n = [name, gem_version]
      n.push(@platform) if @platform != 'ruby'
      "#{n.join('-')}.gem"
    end

    ##
    # Returns the filename of the gemspec file.
    #
    # @param [String] gem_version
    # @return [String]
    #
    def gemspec_filename(gem_version = nil)
      gem_version ||= version.to_s
      n = [name, gem_version]
      n.push(@platform) if @platform != 'ruby'
      "#{n.join('-')}.gemspec.rz"
    end
  end
end
