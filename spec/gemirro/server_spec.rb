require 'rack/test'
require 'json'
require 'parallel'
require 'gemirro/cache'
require 'gemirro/utils'
require 'gemirro/mirror_directory'
require 'gemirro/mirror_file'
require 'gemirro/gem_version_collection'

ENV['RACK_ENV'] = 'test'

# Rspec mixin module
module RSpecMixin
  include Rack::Test::Methods
  def app
    require 'gemirro/server'
    Gemirro::Server
  end
end

RSpec.configure do |c|
  c.include RSpecMixin
end

# Server tests
module Gemirro
  describe 'Gemirro::Server' do
    include FakeFS::SpecHelpers

    before(:each) do
      @fake_logger = Logger.new(STDOUT)
      MirrorDirectory.new('/var/www/gemirro').add_directory('gems')
      MirrorDirectory.new('/').add_directory('tmp')
      MirrorFile.new('/var/www/gemirro/test').write('content')
      Gemirro.configuration.destination = '/var/www/gemirro'
      Utils.instance_eval('@cache = nil')
      Utils.instance_eval('@gems_orig_collection = nil')
      Utils.instance_eval('@gems_source_collection = nil')
      FakeFS::FileSystem.clone(Gemirro::Configuration.views_directory)
    end

    context 'HTML render' do
      it 'should display index page' do
        allow(Logger).to receive(:new).twice.and_return(@fake_logger)
        allow(@fake_logger).to receive(:tap)
          .and_return(nil)
          .and_yield(@fake_logger)

        get '/'
        expect(last_response).to be_ok
      end

      it 'should return 404' do
        get '/wrong-path'
        expect(last_response.status).to eq(404)
        expect(last_response).to_not be_ok
      end

      it 'should return 404 when gem does not exist' do
        get '/gem/something'
        expect(last_response.status).to eq(404)
        expect(last_response).to_not be_ok
      end

      it 'should display gem specifications' do
        marshal_dump = Marshal.dump([['volay',
                                      ::Gem::Version.create('0.1.0'),
                                      'ruby']])

        MirrorFile.new('/var/www/gemirro/specs.4.8.gz.orig').write(marshal_dump)
        Struct.new('SuccessGzipReader', :read)
        gzip_reader = Struct::SuccessGzipReader.new(marshal_dump)
        MirrorDirectory.new('/var/www/gemirro')
                       .add_directory('quick/Marshal.4.8')
        # rubocop:disable Metrics/LineLength
        MirrorFile.new('/var/www/gemirro/quick/Marshal.4.8/' \
                       'volay-0.1.0.gemspec.rz')
                  .write("x\x9C\x8D\x94]\x8F\xD2@\x14\x86\x89Y\xBB\xB4|\xEC\x12\xD7h" \
                         "\xD4h\xD3K\x13J\x01\x97\xC84n\x9A\xA8\xBBi\xE2\xC5\x06\xBB" \
                         "{\xC3\x85)\xE5\x00\x13f:u:E\xD1\xC4\xDF\xE6\xB5\xBF\xCAiK" \
                         "\x11\xE3GK\xEF\x98\xF7\xBC\xCFy\xCF\xC9\xCCQ=A\x0F\xAE\x80" \
                         "\"\xF4>\x82\x00/p\xE0\v\xCC\xC2;\xC1\xDD\xA3\xFA\xF4\xA1k4" \
                         "\x06\xA6e\xF6_(Hy\xEBa\xD55\xB4\r#\xFEV\xB1k\xDE\r\xEAdu" \
                         "\xB7\xC0cY1U\xE4\xA1\x95\x8A\xD3C7A\xAA\x87)\xB4\x9C\x1FO" \
                         "\xBE\xD7\xE4OA\xEA\x17\x16\x82k\xD4o\xBC\xD7\x99\xC2x\xEC" \
                         "\xAD@\xBFe$\xA1\xA0\xC7\xDBX\x00\xD5\x05/\xBC\xEFg\xDE\x13" \
                         "\xF8\x98`\x0E\x14B1U\xE4w\xEC\x1A\xC7\x17\xAF2\x85\xADd\xC4" \
                         "\xBE96\x87\xF9\x1F\xEA\xDF%\x8A\x95\xE3T\x9E\xCC2\xF3i\x9B" \
                         "\xA1\xB3\xCC\xFE\rD\x10\xCE!\f\xB6\x1A\xD2\x9C\xD0\xA7\xB2" \
                         "\xBF\x13\x8A?\x13<\xEB\x06\x04\xA7b\xD4q\xF8\xAF&\x0E!\xDF" \
                         ".~\xEF\xE3\xDC\xCC@\xD2Hl\#@M\x9E\x84BN\x00\x9D:\x11\a\x0E" \
                         "\x04\xFC\x18.\xD1#g\x93\xCF\xEB\xC3\x81m\\\xC1\x97\xD9" \
                         "\x9Af7\\\xE3l\xD7_\xBC\x02BX\"\xD23\xBB\xF9o\x83A\xB1\x12" \
                         "\xBBe\xB7\xED\x93K\xFB\xB4\x82\xB6\x80\xA9K\xB1\x1E\x96" \
                         "\x10\xEA\x03sP\xCD\xBFP\x16\xEE\x8D\x85\xBF\x86E\\\x96" \
                         "\xC02G\xF9\b\xEC\x16:\x9D\xC3\x06\b\x8B\xD2\xA9\x95\x84" \
                         "\xD9\x97\xED\xC3p\x89+\x81\xA9}\xAB`\xD9\x9D\xFF\x03\xF6" \
                         "\xD2\xC2\xBF\xCD\xFD`\xDD\x15\x10\x97\xED\xA4.[\xAB\xC6(" \
                         "\x94\x05B\xE3\xB1\xBC\xA5e\xF6\xC3\xAA\x11\n\xE5>A\x8CiD " \
                         "`\x9B\xF2\x04\xE3\xCA\t\xC6\x87\by-f,`Q\xD9\x1E,sp^q\x0F" \
                         "\x85\xD4r\x8Dg\x11\x06\xCE\xC1\xE4>\x9D\xF9\xC9\xFC\xE5" \
                         "\xC8YR\x1F\x133`4\xBB\xF9R~\xEF:\x93\xE8\x93\\\x92\xBF\r" \
                         "\xA3\t\xF8\x84l\xF5<\xBF\xBE\xF9\xE3Q\xD2?q,\x04\x84:\x0E" \
                         "\xF5\xF4\x1D1\xF3\xBA\xE7+!\"\xD4\xEB-\xB1X%\xB3\x14\xD3" \
                         "\xCB\xEDw\xEE\xBD\xFDk\xE99OSz\xF3\xEA\xFA]w7\xF5\xAF\xB5" \
                         "\x9F+\xFEG\x96")
        # rubocop:enable Metrics/LineLength

        allow(Zlib::GzipReader).to receive(:open)
          .once
          .with('/var/www/gemirro/specs.4.8.gz.orig')
          .and_return(gzip_reader)

        get '/gem/volay'
        expect(last_response.status).to eq(200)
        expect(last_response).to be_ok
      end
    end

    context 'Download' do
      it 'should download existing file' do
        get '/test'
        expect(last_response.body).to eq('content')
        expect(last_response).to be_ok
      end

      it 'should try to download gems.' do
        source = Gemirro::Source.new('test', 'http://rubygems.org')

        versions_fetcher = Gemirro::VersionsFetcher.new(source)
        allow(versions_fetcher).to receive(:fetch).once.and_return(true)

        gems_fetcher = Gemirro::GemsFetcher.new(source, versions_fetcher)
        allow(gems_fetcher).to receive(:fetch).once.and_return(true)
        allow(gems_fetcher).to receive(:gem_exists?).once.and_return(true)

        Struct.new('GemIndexer')
        gem_indexer = Struct::GemIndexer.new
        allow(gem_indexer).to receive(:only_origin=).once.and_return(true)
        allow(gem_indexer).to receive(:ui=).once.and_return(true)
        allow(gem_indexer).to receive(:update_index).once.and_return(true)

        allow(Gemirro.configuration).to receive(:source)
          .twice.and_return(source)
        allow(Gemirro::GemsFetcher).to receive(:new)
          .once.and_return(gems_fetcher)
        allow(Gemirro::VersionsFetcher).to receive(:new)
          .once.and_return(versions_fetcher)
        allow(Gemirro::Indexer).to receive(:new).once.and_return(gem_indexer)
        allow(::Gem::SilentUI).to receive(:new).once.and_return(true)

        allow(Gemirro.configuration).to receive(:logger)
          .exactly(3).and_return(@fake_logger)
        allow(@fake_logger).to receive(:info).exactly(3)

        get '/gems/gemirro-0.0.1.gem'
        expect(last_response).to_not be_ok
        expect(last_response.status).to eq(404)

        MirrorFile.new('/var/www/gemirro/gems/gemirro-0.0.1.gem')
                  .write('content')
        get '/gems/gemirro-0.0.1.gem'
        expect(last_response).to be_ok
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq('content')
      end

      it 'should catch exceptions' do
        source = Gemirro::Source.new('test', 'http://rubygems.org')

        versions_fetcher = Gemirro::VersionsFetcher.new(source)
        allow(versions_fetcher).to receive(:fetch).once.and_return(true)

        gems_fetcher = Gemirro::VersionsFetcher.new(source)
        allow(gems_fetcher).to receive(:fetch)
          .once.and_raise(StandardError, 'Not ok')

        gem_indexer = Struct::GemIndexer.new
        allow(gem_indexer).to receive(:only_origin=).once.and_return(true)
        allow(gem_indexer).to receive(:ui=).once.and_return(true)
        allow(gem_indexer).to receive(:update_index)
          .once.and_raise(SystemExit)

        allow(Gemirro.configuration).to receive(:source)
          .twice.and_return(source)
        allow(Gemirro::GemsFetcher).to receive(:new)
          .once.and_return(gems_fetcher)
        allow(Gemirro::VersionsFetcher).to receive(:new)
          .once.and_return(versions_fetcher)
        allow(Gemirro::Indexer).to receive(:new).once.and_return(gem_indexer)
        allow(::Gem::SilentUI).to receive(:new).once.and_return(true)

        allow(Gemirro.configuration).to receive(:logger)
          .exactly(4).and_return(@fake_logger)
        allow(@fake_logger).to receive(:info).exactly(3)
        allow(@fake_logger).to receive(:error)
        get '/gems/gemirro-0.0.1.gem'
        expect(last_response).to_not be_ok
      end
    end

    context 'dependencies' do
      it 'should retrieve nothing' do
        get '/api/v1/dependencies'
        expect(last_response.headers['Content-Type'])
          .to eq('application/octet-stream')
        expect(last_response.body).to eq('')
        expect(last_response).to be_ok
      end

      it 'should retrieve empty json' do
        get '/api/v1/dependencies.json'
        expect(last_response.headers['Content-Type'])
          .to eq('application/json')
        expect(last_response.body).to eq('')
        expect(last_response).to be_ok
      end

      it 'should retrieve empty json when gem was not found' do
        get '/api/v1/dependencies.json?gems=gemirro'
        expect(last_response.headers['Content-Type'])
          .to eq('application/json')
        expect(last_response.body).to eq('[]')
        expect(last_response).to be_ok
      end

      it 'should retrieve json when gem was found' do
        MirrorDirectory.new('/var/www/gemirro')
                       .add_directory('quick/Marshal.4.8')
        # rubocop:disable Metrics/LineLength
        MirrorFile.new('/var/www/gemirro/quick/Marshal.4.8/' \
                       'volay-0.1.0.gemspec.rz')
                  .write("x\x9C\x8D\x94]\x8F\xD2@\x14\x86\x89Y\xBB\xB4|\xEC\x12\xD7h" \
                         "\xD4h\xD3K\x13J\x01\x97\xC84n\x9A\xA8\xBBi\xE2\xC5\x06\xBB" \
                         "{\xC3\x85)\xE5\x00\x13f:u:E\xD1\xC4\xDF\xE6\xB5\xBF\xCAiK" \
                         "\x11\xE3GK\xEF\x98\xF7\xBC\xCFy\xCF\xC9\xCCQ=A\x0F\xAE\x80" \
                         "\"\xF4>\x82\x00/p\xE0\v\xCC\xC2;\xC1\xDD\xA3\xFA\xF4\xA1k4" \
                         "\x06\xA6e\xF6_(Hy\xEBa\xD55\xB4\r#\xFEV\xB1k\xDE\r\xEAdu" \
                         "\xB7\xC0cY1U\xE4\xA1\x95\x8A\xD3C7A\xAA\x87)\xB4\x9C\x1FO" \
                         "\xBE\xD7\xE4OA\xEA\x17\x16\x82k\xD4o\xBC\xD7\x99\xC2x\xEC" \
                         "\xAD@\xBFe$\xA1\xA0\xC7\xDBX\x00\xD5\x05/\xBC\xEFg\xDE\x13" \
                         "\xF8\x98`\x0E\x14B1U\xE4w\xEC\x1A\xC7\x17\xAF2\x85\xADd\xC4" \
                         "\xBE96\x87\xF9\x1F\xEA\xDF%\x8A\x95\xE3T\x9E\xCC2\xF3i\x9B" \
                         "\xA1\xB3\xCC\xFE\rD\x10\xCE!\f\xB6\x1A\xD2\x9C\xD0\xA7\xB2" \
                         "\xBF\x13\x8A?\x13<\xEB\x06\x04\xA7b\xD4q\xF8\xAF&\x0E!\xDF" \
                         ".~\xEF\xE3\xDC\xCC@\xD2Hl\#@M\x9E\x84BN\x00\x9D:\x11\a\x0E" \
                         "\x04\xFC\x18.\xD1#g\x93\xCF\xEB\xC3\x81m\\\xC1\x97\xD9" \
                         "\x9Af7\\\xE3l\xD7_\xBC\x02BX\"\xD23\xBB\xF9o\x83A\xB1\x12" \
                         "\xBBe\xB7\xED\x93K\xFB\xB4\x82\xB6\x80\xA9K\xB1\x1E\x96" \
                         "\x10\xEA\x03sP\xCD\xBFP\x16\xEE\x8D\x85\xBF\x86E\\\x96" \
                         "\xC02G\xF9\b\xEC\x16:\x9D\xC3\x06\b\x8B\xD2\xA9\x95\x84" \
                         "\xD9\x97\xED\xC3p\x89+\x81\xA9}\xAB`\xD9\x9D\xFF\x03\xF6" \
                         "\xD2\xC2\xBF\xCD\xFD`\xDD\x15\x10\x97\xED\xA4.[\xAB\xC6(" \
                         "\x94\x05B\xE3\xB1\xBC\xA5e\xF6\xC3\xAA\x11\n\xE5>A\x8CiD " \
                         "`\x9B\xF2\x04\xE3\xCA\t\xC6\x87\by-f,`Q\xD9\x1E,sp^q\x0F" \
                         "\x85\xD4r\x8Dg\x11\x06\xCE\xC1\xE4>\x9D\xF9\xC9\xFC\xE5" \
                         "\xC8YR\x1F\x133`4\xBB\xF9R~\xEF:\x93\xE8\x93\\\x92\xBF\r" \
                         "\xA3\t\xF8\x84l\xF5<\xBF\xBE\xF9\xE3Q\xD2?q,\x04\x84:\x0E" \
                         "\xF5\xF4\x1D1\xF3\xBA\xE7+!\"\xD4\xEB-\xB1X%\xB3\x14\xD3" \
                         "\xCB\xEDw\xEE\xBD\xFDk\xE99OSz\xF3\xEA\xFA]w7\xF5\xAF\xB5" \
                         "\x9F+\xFEG\x96")
        # rubocop:enable Metrics/LineLength

        gem = Gemirro::GemVersion.new('volay', '0.1.0', 'ruby')
        collection = Gemirro::GemVersionCollection.new([gem])
        allow(Utils).to receive(:gems_collection)
          .and_return(collection)
        get '/api/v1/dependencies.json?gems=volay'
        expect(last_response.headers['Content-Type'])
          .to eq('application/json')

        expect(last_response.body).to match(/"name":"volay"/)
        expect(last_response).to be_ok
      end
    end
  end
end
