# frozen_string_literal: true

module Gemirro
  ##
  # The Http class is responsible for executing GET request
  # to a specific url and return an response as an HTTP::Message
  #
  # @!attribute [r] client
  #  @return [HTTPClient]
  #
  class Http
    attr_accessor :client

    ##
    # Requests the given HTTP resource.
    #
    # @param [String] url
    # @return [HTTP::Message]
    #
    def self.get(url)
      response = client.get(url, follow_redirect: true)

      raise HTTPClient::BadResponseError, response.reason unless HTTP::Status.successful?(response.status)

      response
    end

    ##
    # @return [HTTPClient]
    #
    def self.client
      client ||= HTTPClient.new
      config = Utils.configuration
      if defined?(config.upstream_user)
        user = config.upstream_user
        password = config.upstream_password
        domain = config.upstream_domain
        client.set_auth(domain, user, password)
      end

      if defined?(config.proxy)
        proxy = config.proxy
        client.proxy=(proxy)
      end

      # Use my own ca file for self signed cert
      if defined?(config.rootca)
          abort "The configuration file #{config.rootca} does not exist" unless File.file?(config.rootca)
          client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_PEER
          client.ssl_config.set_trust_ca(config.rootca)
      elsif defined?(config.verify_mode)
        client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE unless config.verify_mode
      end

      # Enforece base auth
      if defined?(config.basic_auth)
        client.force_basic_auth=(true) if config.basic_auth
        # client.www_auth.reset_challenge()
      end
      @client = client
    end
  end
end
