# -*- coding: utf-8 -*-
module Gemirro
  ##
  # The Source class is used for storing information about an external source
  # such as the name and the Gems to mirror.
  #
  # @!attribute [r] name
  #  @return [String]
  # @!attribute [r] host
  #  @return [String]
  # @!attribute [r] gems
  #  @return [Array]
  #
  class Source
    attr_reader :name, :host, :gems

    ##
    # @param [String] name
    # @param [String] host
    # @param [Array] gems
    #
    def initialize(name, host, gems = [])
      @name = name.downcase.gsub(/\s+/, '_')
      @host = host.chomp('/')
      @gems = gems
    end

    ##
    # Fetches a list of all the available Gems and their versions.
    #
    # @return [String]
    #
    def fetch_versions
      Http.get(host + '/' + Configuration.versions_file).body
    end

    ##
    # Fetches a list of all the available Gems and their versions.
    #
    # @return [String]
    #
    def fetch_prerelease_versions
      Http.get(host + '/' + Configuration.prerelease_versions_file).body
    end

    ##
    # Fetches the `.gem` file of a given Gem and version.
    #
    # @param [String] name
    # @param [String] version
    # @return [String]
    #
    def fetch_gem(name, version)
      Http.get(host + "/gems/#{name}-#{version}.gem").body
    end

    ##
    # Fetches the `.gemspec.rz` file of a given Gem and version.
    #
    # @param [String] name
    # @param [String] version
    # @return [String]
    #
    def fetch_gemspec(name, version)
      marshal = Gemirro::Configuration.marshal_identifier
      Http.get(host + "/quick/#{marshal}/#{name}-#{version}.gemspec.rz").body
    end

    ##
    # Adds a new Gem to the source.
    #
    # @param [String] name
    # @param [String] requirement
    #
    def gem(name, requirement = nil)
      gems << Gem.new(name, requirement)
    end
  end
end
