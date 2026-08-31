# frozen_string_literal: true

module Gemirro
  module CLI
    # `gemirro update` command
    module UpdateCommand
      ##
      # @param [Array] argv
      #
      def self.run(argv)
        options = {}
        option_parser(options).parse!(argv)

        Gemirro::CLI.load_configuration(options[:config])
        config = Gemirro.configuration
        config.logger_level = options[:log_level] if options[:log_level]

        source = config.source
        versions = Gemirro::VersionsFetcher.new(source).fetch
        gems     = Gemirro::GemsFetcher.new(source, versions)

        gems.fetch

        source.gems.each do |gem|
          gem.gemspec = true
        end

        gems.fetch
      end

      ##
      # @param [Hash] options
      # @return [OptionParser]
      #
      def self.option_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: gemirro update [OPTIONS]'
          opts.separator ''
          opts.separator 'Options:'
          opts.separator ''

          opts.on('-c', '--config CONFIG', 'Path to the configuration file') { |v| options[:config] = v }
          opts.on('-l', '--log_level LEVEL', 'Set logger level') { |v| options[:log_level] = v }
          opts.on('-h', '--help', 'Display this help message.') do
            puts opts
            exit
          end
        end
      end
    end
  end
end
