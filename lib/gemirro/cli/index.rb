# frozen_string_literal: true

module Gemirro
  module CLI
    # `gemirro index` command
    module IndexCommand
      ##
      # @param [Array] argv
      #
      def self.run(argv)
        options = {}
        option_parser(options).parse!(argv)

        Gemirro::CLI.load_configuration(options[:config])
        config = Gemirro.configuration
        config.logger_level = options[:log_level] if options[:log_level]
        Gemirro::CLI.ensure_destination!(config)

        indexer    = Gemirro::Indexer.new
        indexer.ui = ::Gem::SilentUI.new

        if File.exist?(File.join(config.versions_file))
          indexer.download_source_versions
          if options[:update]
            config.logger.info('Generating index updates')
            indexer.update_index
          else
            config.logger.info('Generating indexes')
            indexer.generate_index
          end
        else
          config.logger.error("#{File.basename(config.versions_file)} file is missing.")
          config.logger.error('Run "gemirro update" before running index.')
        end
      end

      ##
      # @param [Hash] options
      # @return [OptionParser]
      #
      def self.option_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: gemirro index [OPTIONS]'
          opts.separator ''
          opts.separator 'Options:'
          opts.separator ''

          opts.on('-c', '--config CONFIG', 'Path to the configuration file') { |v| options[:config] = v }
          opts.on('-l', '--log_level LEVEL', 'Set logger level') { |v| options[:log_level] = v }
          opts.on('-u', '--update', 'Update only') { options[:update] = true }
          opts.on('-h', '--help', 'Display this help message.') do
            puts opts
            exit
          end
        end
      end
    end
  end
end
