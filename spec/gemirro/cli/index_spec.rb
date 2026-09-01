require 'spec_helper'
require 'gemirro/cli'
require 'gemirro/mirror_directory'

module Gemirro
  module CLI
    describe 'IndexCommand' do
      include FakeFS::SpecHelpers

      let(:config) { Configuration.new }

      before do
        MirrorDirectory.new('/').add_directory('public')
        allow(Gemirro::CLI).to receive(:load_configuration)
        allow(Gemirro).to receive(:configuration).and_return(config)
        config.destination = '/public'
        config.define_source('rubygems', 'https://rubygems.org') {}
      end

      it 'reports the missing versions file without raising' do
        require 'gemirro/cli/index'

        expect(config.logger).to receive(:error).with(/file is missing/)
        expect(config.logger).to receive(:error)
          .with('Run "gemirro update" before running index.')

        expect { IndexCommand.run(['-c', 'config.rb']) }.not_to raise_error
      end
    end
  end
end
