# frozen_string_literal: true

module Gemirro
  ##
  # The Http class is responsible for executing GET requests against a
  # given URL, following redirects and reusing keep-alive connections.
  #
  class Http
    ##
    # Raised when a request comes back with a non-successful,
    # non-redirect HTTP status.
    #
    class Error < StandardError; end

    MAX_REDIRECTS = 10

    class << self
      ##
      # Requests the given HTTP resource, following redirects.
      #
      # @param [String] url
      # @return [Net::HTTPResponse]
      #
      def get(url)
        fetch(URI.parse(url), MAX_REDIRECTS)
      end

      ##
      # Closes and forgets every connection cached for the current
      # Thread. Mostly useful for tests.
      #
      def reset!
        pool.each_value { |connection| connection.finish if connection.started? }
        pool.clear
      end

      private

      ##
      # @param [URI] uri
      # @param [Integer] redirects_left
      # @return [Net::HTTPResponse]
      #
      def fetch(uri, redirects_left)
        response = connection_for(uri).request(build_request(uri))

        case response
        when Net::HTTPRedirection
          raise Error, "Too many redirects for #{uri}" if redirects_left <= 0

          fetch(URI.parse(response['location']), redirects_left - 1)
        when Net::HTTPSuccess
          response
        else
          raise Error, "#{response.code} #{response.message}"
        end
      end

      ##
      # @param [URI] uri
      # @return [Net::HTTP::Get]
      #
      def build_request(uri)
        request = Net::HTTP::Get.new(uri)
        config = Utils.configuration
        request.basic_auth(config.upstream_user, config.upstream_password) if defined?(config.upstream_user)

        request
      end

      ##
      # Returns a started, keep-alive connection for the given URI,
      # reusing one already opened by the current Thread when possible.
      #
      # @param [URI] uri
      # @return [Net::HTTP]
      #
      def connection_for(uri)
        key = "#{uri.scheme}://#{uri.host}:#{uri.port}"
        pool[key] ||= build_connection(uri)
      end

      ##
      # Connection pool for the current Thread. Kept per-Thread so
      # sockets are never shared/interleaved across concurrent requests.
      #
      # @return [Hash]
      #
      def pool
        Thread.current[:gemirro_http_pool] ||= {}
      end

      ##
      # @param [URI] uri
      # @return [Net::HTTP]
      #
      def build_connection(uri)
        config = Utils.configuration
        http = Net::HTTP.new(uri.host, uri.port, *proxy_args(config))
        http.use_ssl = uri.scheme == 'https'
        configure_ssl(http, config)

        http.start
      end

      ##
      # @param [Net::HTTP] http
      # @param [Gemirro::Configuration] config
      #
      def configure_ssl(http, config)
        if defined?(config.rootca)
          abort "The configuration file #{config.rootca} does not exist" unless File.file?(config.rootca)

          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_file = config.rootca
        elsif defined?(config.verify_mode) && !config.verify_mode
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      ##
      # Splits a `proxy 'http://user:pass@host:port'` configuration
      # value into the args expected by `Net::HTTP.new`.
      #
      # @param [Gemirro::Configuration] config
      # @return [Array]
      #
      def proxy_args(config)
        return [] unless defined?(config.proxy) && config.proxy

        proxy_uri = URI.parse(config.proxy)
        [proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password]
      end
    end
  end
end
