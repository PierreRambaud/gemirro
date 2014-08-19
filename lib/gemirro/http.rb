# -*- coding: utf-8 -*-

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

      unless HTTP::Status.successful?(response.status)
        fail HTTPClient::BadResponseError, response.reason
      end

      response
    end

    ##
    # @return [HTTPClient]
    #
    def self.client
      @client ||= HTTPClient.new
    end
  end
end
