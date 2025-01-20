require 'spec_helper'
require 'httpclient'
require 'gemirro/http'

module Gemirro
  describe Http do
    let(:config) { double('Configuration') }

    before do
      Http.instance_variable_set(:@client, nil)
      allow(Utils).to receive(:configuration).and_return(config)
    end

    describe '.client' do
      it 'initializes a new HTTPClient' do
        expect(Http.client).to be_a(HTTPClient)
      end

      context 'with proxy configuration' do
        it 'sets proxy configuration' do
          allow(config).to receive(:proxy).and_return('http://proxy.example.com:8080')

          expect(Http.client.proxy.to_s).to eq('http://proxy.example.com:8080')
        end
      end

      context 'with SSL configuration' do
        context 'with invalid root CA path' do
          before do
            allow(config).to receive(:rootca).and_return('/nonexistent/ca.crt')
            allow(File).to receive(:file?).with('/nonexistent/ca.crt').and_return(false)
          end

          it 'aborts with error message' do
            expect { Http.client }.to raise_error(SystemExit)
          end
        end

        context 'with verify_mode disabled' do
          before do
            allow(config).to receive(:verify_mode).and_return(false)
          end

          it 'sets SSL verify mode to VERIFY_NONE' do
            expect(Http.client.ssl_config.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
          end
        end
      end

      context 'with basic auth forced' do
        before do
          allow(config).to receive(:basic_auth).and_return(true)
        end

        it 'forces basic authentication' do
          expect(Http.client.www_auth.basic_auth.force_auth).to be true
        end
      end
    end

    describe '.get' do
      let(:client) { instance_double(HTTPClient) }

      before do
        allow(Http).to receive(:client).and_return(client)
      end

      context 'with successful response' do
        let(:response) { double('Response', status: 200, body: 'content') }

        it 'returns response for successful request' do
          allow(client).to receive(:get)
            .with('http://example.com', follow_redirect: true)
            .and_return(response)

          expect(Http.get('http://example.com')).to eq(response)
        end
      end

      context 'with error response' do
        let(:response) { double('Response', status: 404, reason: 'Not Found') }

        it 'raises BadResponseError for failed request' do
          allow(client).to receive(:get)
            .with('http://example.com', follow_redirect: true)
            .and_return(response)

          expect { Http.get('http://example.com') }
            .to raise_error(HTTPClient::BadResponseError, 'Not Found')
        end
      end
    end
  end
end