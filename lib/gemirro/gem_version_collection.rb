# -*- coding: utf-8 -*-
module Gemirro
  ##
  # The VersionCollection class contains a collection of ::Gem::Version
  #
  # @!attribute [r] gems
  #  @return [Array]
  # @!attribute [r] grouped
  #  @return [Array]
  #
  class GemVersionCollection
    include Enumerable

    attr_reader :gems
    attr_reader :grouped

    ##
    # @params [Array] gems
    #
    def initialize(gems = [])
      @gems = gems.map do |object|
        if object.is_a?(GemVersion)
          object
        else
          GemVersion.new(*object)
        end
      end
    end

    ##
    # Return oldest version of a gem
    #
    # @return [GemVersion]
    #
    def oldest
      @gems.first
    end

    ##
    # Return newest version of a gem
    #
    # @return [GemVersion]
    #
    def newest
      @gems.last
    end

    ##
    # Return size of a gem
    #
    # @reutnr [Integer]
    #
    def size
      @gems.size
    end

    ##
    # Each method
    #
    def each(&block)
      @gems.each(&block)
    end

    ##
    # Group gems by name
    #
    # @param [Proc] &block
    # @return [Array]
    #
    def by_name(&block)
      if @grouped.nil?
        @grouped = @gems.group_by(&:name).map do |name, collection|
          [name, GemVersionCollection.new(collection)]
        end
        @grouped.sort_by! do |name, _collection|
          name.downcase
        end
      end

      if block_given?
        @grouped.each(&block)
      else
        @grouped
      end
    end

    ##
    # Find gem by name
    #
    # @param [String] gemname
    # @return [Array]
    #
    def find_by_name(gemname)
      by_name.select do |name, _collection|
        name == gemname
      end
    end
  end
end
