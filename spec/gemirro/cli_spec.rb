require 'spec_helper'
require 'gemirro/cli'
require 'gemirro/mirror_file'

# Gemirro tests
module Gemirro
  # CLI tests
  module CLI
    describe 'CLI' do
      include FakeFS::SpecHelpers

      it 'should print version information for -v' do
        expect { CLI.run(['-v']) }.to output(/gemirro v.* on ruby/).to_stdout
      end

      it 'should print version information for --version' do
        expect { CLI.run(['--version']) }.to output(/gemirro v.* on ruby/).to_stdout
      end

      it 'should print usage for -h' do
        expect { CLI.run(['-h']) }.to output(/Usage: gemirro \[COMMAND\] \[OPTIONS\]/).to_stdout
      end

      it 'should print usage for --help' do
        expect { CLI.run(['--help']) }.to output(/Usage: gemirro \[COMMAND\] \[OPTIONS\]/).to_stdout
      end

      it 'should print usage when no argument is given' do
        expect { CLI.run([]) }.to output(/Usage: gemirro \[COMMAND\] \[OPTIONS\]/).to_stdout
      end

      it 'should list the available commands in the usage banner' do
        output = capture_stdout { CLI.run(['-h']) }

        CLI::COMMANDS.each do |name, description|
          expect(output).to match(/#{name}(\s+)#{Regexp.escape(description)}/)
        end
      end

      it 'should set $PROGRAM_NAME' do
        $PROGRAM_NAME = 'rspec'
        CLI.run(['-v'])
        expect($PROGRAM_NAME).to eq('gemirro')
      end

      it 'should print an error and exit for an unknown command' do
        expect { CLI.run(['nope']) }.to output(/Unknown command: nope/).to_stdout.and raise_error(SystemExit)
      end

      it 'should print an option error for an unknown flag' do
        expect { CLI.run(['list', '--nope']) }
          .to output(/invalid option: --nope/).to_stdout.and raise_error(SystemExit)
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

      def capture_stdout
        original = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original
      end
    end
  end
end
