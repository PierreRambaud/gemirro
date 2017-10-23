require 'spec_helper'
require 'gemirro/cli'
require 'gemirro/mirror_file'
require 'slop'

# Gemirro tests
module Gemirro
  # CLI tests
  module CLI
    describe 'CLI' do
      include FakeFS::SpecHelpers

      it 'should return options' do
        options = CLI.options
        expect(options).to be_a(::Slop)
        expect(options.config[:strict]).to be_truthy
        expect(options.config[:banner])
          .to eq('Usage: gemirro [COMMAND] [OPTIONS]')
        expect(options.to_s)
          .to match(/-v, --version(\s+)Shows the current version/)
        expect(options.to_s)
          .to match(/-h, --help(\s+)Display this help message./)

        version = options.fetch_option(:v)
        expect(version.short).to eq('v')
        expect(version.long).to eq('version')
        expect { version.call }.to output(/gemirro v.* on ruby/).to_stdout
      end

      it 'should retrieve version information' do
        expect(CLI.version_information).to eq(
          "gemirro v#{VERSION} on #{RUBY_DESCRIPTION}"
        )
      end

      it 'should raise SystemExit if file does not exists' do
        allow(CLI).to receive(:abort)
          .with('The configuration file /config.rb does not exist')
          .and_raise SystemExit
        expect { CLI.load_configuration('config.rb') }.to raise_error SystemExit
      end

      it 'should raise LoadError if content isn\'t ruby' do
        file = MirrorFile.new('./config.rb')
        file.write('test')
        expect { CLI.load_configuration('config.rb') }.to raise_error LoadError
      end
    end
  end
end
