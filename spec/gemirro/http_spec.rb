require 'spec_helper'
require 'webmock/rspec'
require 'gemirro/utils'
require 'gemirro/http'

module Gemirro
  describe Http do
    let(:config) { double('Configuration') }

    before do
      Http.reset!
      allow(Utils).to receive(:configuration).and_return(config)
    end

    after { Http.reset! }

    describe '.get' do
      context 'with successful response' do
        it 'returns the response' do
          stub_request(:get, 'http://example.com/').to_return(status: 200, body: 'content')

          response = Http.get('http://example.com/')
          expect(response).to be_a(Net::HTTPSuccess)
          expect(response.body).to eq('content')
        end

        it 'reuses the connection for a second request on the same host' do
          stub_request(:get, 'http://example.com/one').to_return(status: 200, body: 'one')
          stub_request(:get, 'http://example.com/two').to_return(status: 200, body: 'two')

          Http.get('http://example.com/one')
          Http.get('http://example.com/two')

          expect(a_request(:get, 'http://example.com/one')).to have_been_made.once
          expect(a_request(:get, 'http://example.com/two')).to have_been_made.once
        end
      end

      context 'with a redirect' do
        it 'follows it and returns the final response' do
          stub_request(:get, 'http://example.com/old')
            .to_return(status: 302, headers: { 'Location' => 'http://example.com/new' })
          stub_request(:get, 'http://example.com/new').to_return(status: 200, body: 'moved')

          expect(Http.get('http://example.com/old').body).to eq('moved')
        end

        it 'raises after too many redirects' do
          stub_request(:get, 'http://example.com/loop')
            .to_return(status: 302, headers: { 'Location' => 'http://example.com/loop' })

          expect { Http.get('http://example.com/loop') }
            .to raise_error(Http::Error, /Too many redirects/)
        end
      end

      context 'with an error response' do
        it 'raises Http::Error for a failed request' do
          stub_request(:get, 'http://example.com/missing').to_return(status: [404, 'Not Found'])

          expect { Http.get('http://example.com/missing') }
            .to raise_error(Http::Error, '404 Not Found')
        end
      end

      context 'with upstream authentication configured' do
        it 'sends a basic auth header on every request' do
          allow(config).to receive(:upstream_user).and_return('user')
          allow(config).to receive(:upstream_password).and_return('pass')
          stub_request(:get, 'http://example.com/private')
            .with(basic_auth: %w[user pass])
            .to_return(status: 200, body: 'ok')

          expect(Http.get('http://example.com/private').body).to eq('ok')
        end
      end

      context 'with proxy configuration' do
        it 'routes the request through the configured proxy' do
          allow(config).to receive(:proxy).and_return('http://proxy.example.com:8080')
          stub_request(:get, 'http://example.com/').to_return(status: 200, body: 'content')

          Http.get('http://example.com/')

          expect(WebMock).to have_requested(:get, 'http://example.com/')
        end
      end

      context 'with an invalid rootca path' do
        it 'aborts with an error message' do
          allow(config).to receive(:rootca).and_return('/nonexistent/ca.crt')

          expect { Http.get('https://example.com/') }.to raise_error(SystemExit)
        end
      end
    end
  end
end
