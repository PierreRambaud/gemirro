# frozen_string_literal: true

require 'sinatra/base'
require 'thin'
require 'uri'
require 'addressable/uri'

module Gemirro
  ##
  # Launch Sinatra server to easily download gems.
  #
  class Server < Sinatra::Base
    access_logger = Logger.new(Utils.configuration.server.access_log).tap do |logger|
      ::Logger.class_eval { alias_method :write, :<< }
      logger.level = ::Logger::INFO
    end

    error_logger = File.new(Utils.configuration.server.error_log, 'a+')
    error_logger.sync = true

    before do
      env['rack.errors'] = error_logger
      Utils.configuration.logger = access_logger
    end

    ##
    # Configure server
    #
    configure do
      config = Utils.configuration
      config.server.host = 'localhost' if config.server.host.nil?
      config.server.port = '2000' if config.server.port.nil?

      set :static, true

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
      gems = Utils.gems_collection
      gem = gems.find_by_name(params[:gemname])
      return not_found if gem.nil?

      erb(:gem, {}, gem: gem)
    end

    ##
    # Display home page containing the list of gems already
    # downloaded on the server
    #
    # @return [nil]
    #
    get('/') do
      erb(:index, {}, gems: Utils.gems_collection)
    end

    ##
    # Return gem dependencies as binary
    #
    # @return [nil]
    #
    get '/api/v1/dependencies' do
      content_type 'application/octet-stream'
      if params[:gems].to_s != '' && params[:gems].to_s.split(',').any?
        Marshal.dump(dependencies_loader(params[:gems].to_s.split(',')))
      else
        200
      end
    end

    ##
    # Return gem dependencies as json
    #
    # @return [nil]
    #
    get '/api/v1/dependencies.json' do
      content_type 'application/json'
      if params[:gems]
        if params[:gems].to_s.split(',').any?
          JSON.dump(dependencies_loader(params[:gems].to_s.split(',')))
        else
          '[]'
        end
      else
        ''
      end
    end

    ##
    # Return gem list as compact_index
    #
    # @return [nil]
    #
    get '/names' do
      content_type 'text/plain'

      content_path = Dir.glob(File.join(settings.public_folder, 'names.*.*.list')).last
      _, etag, repr_digest, _ = content_path.split('.', -4)

      headers 'etag' => etag
      headers 'repr-digest' => %(sha-256="#{repr_digest}")
      send_file content_path
    end

    ##
    # Return gem versions as compact_index
    #
    # @return [nil]
    #
    get '/versions' do
      content_type 'text/plain'

      content_path = Dir.glob(File.join(settings.public_folder, 'versions.*.*.list')).last
      _, etag, repr_digest, _ = content_path.split('.', -4)

      headers 'etag' => etag
      headers 'repr-digest' => %(sha-256="#{repr_digest}")
      send_file content_path
    end

    # Return gem dependencies as compact_index
    #
    # @return [nil]
    #
    get('/info/:gemname') do
      gems = Utils.gems_collection
      gem = gems.find_by_name(params[:gemname])
      return not_found if gem.nil?

      content_type 'text/plain'

      content_path = Dir.glob(File.join(settings.public_folder, 'info', "#{params[:gemname]}.*.*.list")).last
      _, etag, repr_digest, _ = content_path.split('.', -4)

      headers 'etag' => etag
      headers 'repr-digest' => %(sha-256="#{repr_digest}")
      send_file content_path
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
      Gemirro::Utils.fetch_gem(resource) unless File.exist?(resource)
      # If not found again, return a 404
      return not_found unless File.exist?(resource)

      send_file(resource)
    end

    def dependencies_loader(names)
      names.collect do |name|
        f = File.join(settings.public_folder, 'api', 'v1', 'dependencies', "#{name}.*.*.list")
        Marshal.load(File.read(Dir.glob(f).last))
      rescue StandardError => e
        env['rack.errors'].write "Cound not open #{f}\n"
        env['rack.errors'].write "#{e.message}\n"
        e.backtrace.each do |err|
          env['rack.errors'].write "#{err}\n"
        end
        nil
      end
      .flatten
      .compact
    end
  end
end
