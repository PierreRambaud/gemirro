require 'spec_helper'
require 'httpclient'
require 'gemirro/http'

# Http tests
module Gemirro
  describe 'Http' do
    it 'should return http client' do
      expect(Http.client).to be_a(HTTPClient)
    end

    it 'should raise error when get request failed' do
      uri = 'http://github.com/PierreRambaud'
      Struct.new('HTTPError', :status, :reason)
      result = Struct::HTTPError.new(401, 'Unauthorized')
      allow(Http.client).to receive(:get)
        .once.with(uri, follow_redirect: true).and_return(result)
      expect { Http.get(uri) }
        .to raise_error HTTPClient::BadResponseError, 'Unauthorized'
    end

    it 'should execute get request' do
      uri = 'http://github.com/PierreRambaud'
      Struct.new('HTTPResponse', :status, :body)
      result = Struct::HTTPResponse.new(200, 'body content')
      allow(Http.client).to receive(:get)
        .once.with(uri, follow_redirect: true).and_return(result)

      response = Http.get(uri)
      expect(response).to be_a(Struct::HTTPResponse)
      expect(response.body).to eq('body content')
      expect(response.status).to eq(200)
    end
  end
end
