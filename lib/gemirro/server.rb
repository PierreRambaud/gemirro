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

    # rubocop:disable Metrics/LineLength
    access_logger = Logger.new(Gemirro.configuration.server.access_log).tap do |logger|
      ::Logger.class_eval { alias_method :write, :'<<' }
      logger.level = ::Logger::INFO
    end
    # rubocop:enable Metrics/LineLength

    error_logger = File.new(Gemirro.configuration.server.error_log, 'a+')
    error_logger.sync = true

    before do
      Gemirro.configuration.logger = access_logger
      env['rack.errors'] = error_logger
    end

    ##
    # Configure server
    #
    configure do
      config = Gemirro.configuration
      config.server.host = 'localhost' if config.server.host.nil?
      config.server.port = '2000' if config.server.port.nil?

      set :views, Gemirro::Configuration.views_directory
      set :port, config.server.port
      set :bind, config.server.host
      set :public_folder, config.destination.gsub(%r{/$}, '')
      set :environment, config.environment
      set :dump_errors, true
      set :raise_errors, true

      enable :logging
      use Rack::CommonLogger, access_logger
    end

    ##
    # Set template for not found action
    #
    # @return [nil]
    #
    not_found do
      content_type 'text/html'
      erb(:not_found)
    end

    ##
    # Display information about one gem
    #
    # @return [nil]
    #
    get('/gem/:gemname') do
      gems = gems_collection
      @gem = gems.find_by_name(params[:gemname])
      return not_found if @gem.nil?

      erb(:gem)
    end

    ##
    # Display home page containing the list of gems already
    # downloaded on the server
    #
    # @return [nil]
    #
    get('/') do
      @gems = gems_collection
      erb(:index)
    end

    ##
    # Return gem dependencies as binary
    #
    # @return [nil]
    #
    get '/api/v1/dependencies' do
      content_type 'application/octet-stream'
      query_gems.any? ? Marshal.dump(query_gems_list) : 200
    end

    ##
    # Return gem dependencies as json
    #
    # @return [nil]
    #
    get '/api/v1/dependencies.json' do
      content_type 'application/json'
      query_gems.any? ? JSON.dump(query_gems_list) : {}
    end

    ##
    # Try to get all request and download files
    # if files aren't found.
    #
    # @return [nil]
    #
    get('*') do |path|
      resource = "#{settings.public_folder}#{path}"

      # Try to download gem
      fetch_gem(resource) unless File.exist?(resource)
      # If not found again, return a 404
      return not_found unless File.exist?(resource)

      send_file(resource)
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
      # rubocop:disable Metrics/LineLength
      regexp = /^(.*)-(\d+(?:\.\d+){2,4}.*?)(?:-x86-(?:(?:mswin|mingw)(?:32|64)).*?)?\.gem(?:spec\.rz)?$/
      # rubocop:enable Metrics/LineLength
      result = name.match(regexp)
      return unless result

      gem_name, gem_version = result.captures
      return unless gem_name && gem_version

      begin
        gem = Gemirro::Gem.new(gem_name, gem_version)
        return if gems_fetcher.gem_exists?(gem.filename(gem_version))

        logger.info("Try to download #{gem_name} with version #{gem_version}")
        gems_fetcher.source.gems.clear
        gems_fetcher.source.gems.push(gem)
        gems_fetcher.fetch

        update_indexes if configuration.update_on_fetch
      rescue StandardError => e
        logger.error(e.message)
      end
    end

    ##
    # Update indexes files
    #
    # @return [Indexer]
    #
    def update_indexes
      indexer    = Gemirro::Indexer.new(configuration.destination)
      indexer.only_origin = true
      indexer.ui = ::Gem::SilentUI.new

      configuration.logger.info('Generating indexes')
      indexer.update_index
    rescue SystemExit => e
      configuration.logger.info(e.message)
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
      @versions_fetcher ||= Gemirro::VersionsFetcher
                            .new(configuration.source).fetch
    end

    ##
    # @return [Gemirro::GemsFetcher]
    #
    def gems_fetcher
      @gems_fetcher ||= Gemirro::GemsFetcher.new(
        configuration.source, versions_fetcher)
    end

    ##
    # Return all gems pass to query
    #
    # @return [Array]
    #
    def query_gems
      params[:gems].to_s.split(',')
    end

    ##
    # @see Gemirro::Configuration#logger
    # @return [Logger]
    #
    def logger
      configuration.logger
    end

    ##
    # Generate Gems collection from Marshal dump
    #
    # @param [TrueClass|FalseClass] orig Fetch orig files
    # @return [Gemirro::GemVersionCollection]
    #
    def gems_collection(orig = true)
      gems = specs_files_paths(orig).map do |specs_file_path|
        if File.exist?(specs_file_path)
          Marshal.load(Zlib::GzipReader.open(specs_file_path).read)
        else
          []
        end
      end.inject(:|)

      GemVersionCollection.new(gems)
    end

    ##
    # Return gems list from query params
    #
    # @return [Array]
    #
    def query_gems_list
      gems = query_gems.flat_map do |query_gem|
        gem_dependencies(query_gem)
      end
      gems = gems.select do |g|
        !g.empty?
      end
      gems
    end

    ##
    # List of versions and dependencies of each version
    # from a gem name.
    #
    # @return [Array]
    #
    def gem_dependencies(gem_name)
      gems = gems_collection(false)
      gem_collection = gems.find_by_name(gem_name)
      return '' if gem_collection.nil?

      gem_collection = gem_collection.map do |gem|
        [gem, spec_for(gem.name, gem.number, gem.platform)]
      end

      gem_collection.reject! do |_, spec|
        spec.nil?
      end

      gem_collection.map do |gem, spec|
        dependencies = spec.dependencies.select do |d|
          d.type == :runtime
        end

        dependencies.map! do |d|
          [d.name.is_a?(Array) ? d.name.first : d.name, d.requirement.to_s]
        end

        {
          name: gem.name,
          number: gem.number,
          platform: gem.platform,
          dependencies: dependencies
        }
      end
    end

    ##
    # Return specs fils paths
    #
    # @param [TrueClass|FalseClass] orig Fetch orig files
    # @return [Array]
    #
    def specs_files_paths(orig = true)
      marshal_version = Gemirro::Configuration.marshal_version
      specs_file_types.map do |specs_file_type|
        File.join(settings.public_folder,
                  [specs_file_type,
                   marshal_version,
                   'gz' + (orig ? '.orig' : '')
                  ].join('.'))
      end
    end

    ##
    # Return specs fils types
    #
    # @return [Array]
    #
    def specs_file_types
      [:specs, :prerelease_specs]
    end

    helpers do
      ##
      # Return gem specification from gemname and version
      #
      # @param [String] gemname
      # @param [String] version
      # @return [::Gem::Specification]
      #
      def spec_for(gemname, version, platform = 'ruby')
        filename = [gemname, version]
        filename.push(platform) if platform != 'ruby'
        gemspec_path = File.join('quick',
                                 Gemirro::Configuration.marshal_identifier,
                                 "#{filename.join('-')}.gemspec.rz")
        spec_file = File.join(settings.public_folder,
                              gemspec_path)

        fetch_gem(gemspec_path) unless File.exist?(spec_file)
        File.open(spec_file, 'r') do |uz_file|
          uz_file.binmode
          Marshal.load(::Gem.inflate(uz_file.read))
        end if File.exist?(spec_file)
      end
    end
  end
end
