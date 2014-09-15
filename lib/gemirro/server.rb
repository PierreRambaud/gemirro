# -*- coding: utf-8 -*-
require 'sinatra/base'
require 'thin'

module Gemirro
  ##
  # Launch Sinatra server to easily download gems.
  #
  # @!attribute [r] versions_fetcher
  #  @return [VersionsFetcher]
  # @!attribute [r] gems_fetcher
  #  @return [Gemirro::GemsFetcher]
  #
  class Server < Sinatra::Base
    attr_accessor :versions_fetcher, :gems_fetcher

    ##
    # Configure server
    #
    configure do
      config = Gemirro.configuration
      config.server_host = 'localhost' if config.server_host.nil?
      config.server_port = '2000' if config.server_port.nil?
      set :port, config.server_port
      set :bind, config.server_host
      set :destination, config.destination.gsub(/\/$/, '')
    end

    ##
    # Try to get all request and download files
    # if files aren't found.
    #
    # @return [nil]
    #
    get('*') do |path|
      resource = "#{settings.destination}#{path}"

      # Try to download gem if file doesn't exists
      fetch_gem(resource) unless File.exist?(resource)
      # If not found again, return a 404
      return not_found unless File.exist?(resource)

      if File.directory?(resource)
        display_directory(resource)
      else
        send_file resource
      end
    end

    ##
    # Try to fetch gem and download its if it's possible, and
    # build and install indicies.
    #
    # @param [String] resource
    # @return [Indexer]
    #
    def fetch_gem(resource)
      name = File.basename(resource)
      regexp = /^(.*)-(\d+(?:\.\d+){,4})\.gem(?:spec\.rz)?$/
      result = name.match(regexp)
      return unless result

      gem_name, gem_version = result.captures
      return unless gem_name && gem_version

      logger.info("Try to download #{gem_name} with version #{gem_version}")

      begin
        gems_fetcher.source.gems.clear
        gems_fetcher.source.gems.push(Gemirro::Gem.new(gem_name, gem_version))
        gems_fetcher.fetch
      rescue StandardError => e
        logger.error(e.message)
      end

      generate_index
    end

    ##
    # Generate index and install indicies.
    #
    # @return [Indexer]
    #
    def generate_index
      indexer    = Indexer.new(settings.destination)
      indexer.ui = ::Gem::SilentUI.new

      logger.info('Generating indexes')
      indexer.generate_index
    end

    ##
    # Display directory on the current sesion
    #
    # @param [String] resource
    # @return [Array]
    #
    def display_directory(resource)
      base_dir = Dir.new(resource)
      base_dir.entries.sort.map do |f|
        dir_sign = ''
        resource_path = resource.gsub(/\/$/, '') + '/' + f
        dir_sign = '/' if File.directory?(resource_path)
        resource_path = resource_path.gsub(/^public\//, '')
        resource_path = resource_path.gsub(settings.destination, '')
        "<a href=\"#{resource_path}\">#{f}#{dir_sign}</a><br>" \
          unless ['.', '..'].include?(File.basename(resource_path))
      end.compact
    end

    ##
    # @see Gemirro::Configuration#logger
    # @return [Logger]
    #
    def logger
      configuration.logger
    end

    ##
    # @see Gemirro.configuration
    #
    def configuration
      Gemirro.configuration
    end

    ##
    # @see Gemirro::VersionsFetcher.fetch
    #
    def versions_fetcher
      @versions_fetcher ||= Gemirro::VersionsFetcher.new(configuration.source).fetch
    end

    ##
    # @return [Gemirro::GemsFetcher]
    #
    def gems_fetcher
      @gems_fetcher ||= Gemirro::GemsFetcher.new(
        configuration.source, versions_fetcher)
    end
  end
end
