# -*- coding: utf-8 -*-

module Gemirro
  ##
  # Launch TCPServer to easily download gems.
  #
  # @!attribute [r] server
  #  @return [TCPServer]
  # @!attribute [r] destination
  #  @return [String]
  # @!attribute [r] versions_fetcher
  #  @return [VersionsFetcher]
  # @!attribute [r] gems_fetcher
  #  @return [Gemirro::GemsFetcher]
  #
  class Server
    attr_reader :server, :destination, :versions_fetcher, :gems_fetcher

    ##
    # Initialize Server
    #
    def initialize
      configuration.server_host = 'localhost' if configuration.server_host.nil?
      configuration.server_port = '2000' if configuration.server_port.nil?
      logger.info('Running server on ' \
                  "#{configuration.server_host}:#{configuration.server_port}")
      @server = TCPServer.new(
        configuration.server_host,
        configuration.server_port
      )

      @destination = configuration.destination
    end

    ##
    # Run the server and accept all connection
    #
    # @return [nil]
    #
    def run
      while (session = server.accept)
        request = session.gets
        logger.info(request)

        trimmedrequest = request.gsub(/GET\ \//, '').gsub(/\ HTTP.*/, '').chomp
        resource = "#{@destination}/#{trimmedrequest}"

        # Try to download gem if file doesn't exists
        fetch_gem(resource) unless File.exist?(resource)

        # If not found again, return a 404
        unless File.exist?(resource)
          logger.warn("404 - #{trimmedrequest.gsub(/^public\//, '')}")
          session.print "HTTP/1.1 404/Object Not Found\r\n\r\n"
          session.close
          next
        end

        if File.directory?(resource)
          display_directory(session, resource)
        else
          mime_type = MIME::Types.type_for(resource)
          session.print "HTTP/1.1 200/OK\r\nContent-type:#{mime_type}\r\n\r\n"
          file = open(resource, 'rb')
          session.puts(file.read)
        end

        session.close
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
      gem_name, gem_version = name.match(regexp).captures

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
      indexer    = Indexer.new(configuration.destination)
      indexer.ui = ::Gem::SilentUI.new

      logger.info('Generating indexes')
      indexer.generate_index
    end

    ##
    # Display directory on the current sesion
    #
    # @param [TCPSocket] session
    # @param [String] resource
    # @return [Array]
    #
    def display_directory(session, resource)
      session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
      base_dir = Dir.new(resource)
      base_dir.entries.sort.each do |f|
        dir_sign = ''
        resource_path = resource.gsub(/\/$/, '') + '/' + f
        dir_sign = '/' if File.directory?(resource_path)
        resource_path = resource_path.gsub(/^public\//, '')
        resource_path = resource_path.gsub(@destination, '')

        session.print(
          "<a href=\"#{resource_path}\">#{f}#{dir_sign}</a><br>"
        ) unless ['.', '..'].include?(File.basename(resource_path))
      end
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
      @gems_fetcher = Gemirro::GemsFetcher.new(
        configuration.source, versions_fetcher)
    end
  end
end
