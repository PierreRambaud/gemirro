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
      @client ||= HTTPClient.new
    end
  end
end
