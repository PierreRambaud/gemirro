# -*- coding: utf-8 -*-
module Gemirro
  ##
  # The Gem class contains data about a Gem such as the name, requirement as
  # well as providing some methods to more easily extract the specific version
  # number.
  #
  # @!attribute [r] name
  #  @return [String]
  # @!attribute [r] number
  #  @return [Integer]
  # @!attribute [r] platform
  #  @return [String]
  #
  class GemVersion
    attr_reader :name, :number, :platform

    ##
    # @param [String] name
    # @param [String] number
    # @param [String] platform
    #
    def initialize(name, number, platform)
      @name     = name
      @number   = number
      @platform = platform
    end

    ##
    # Is for ruby
    #
    # @return [Boolean]
    #
    def ruby?
      !(@platform =~ /ruby/i).nil?
    end

    ##
    # Retrieve gem version
    #
    # @return [Gem::Version]
    #
    def version
      ::Gem::Version.create(number)
    end

    ##
    # Compare gem to another
    #
    # @return [Integer]
    #
    def <=>(other)
      sort = other.name <=> @name
      sort = other.version <=> @version if sort.zero?
      sort = (other.ruby? && !ruby?) ? 1 : -1 if sort.zero? &&
                                                 ruby? != other.ruby?
      sort = other.platform <=> @platform if sort.zero?

      sort
    end

    ##
    # Gemfile name
    #
    # @return [String]
    #
    def gemfile_name
      [@name, @number, @platform].compact.join('-')
    end
  end
end
