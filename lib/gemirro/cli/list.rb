# frozen_string_literal: true

module Gemirro
  module CLI
    # `gemirro list` command
    module ListCommand
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

        gems = Gemirro::Utils.gems_collection.group_by(&:name).sort
        gems.each do |name, versions|
          puts "#{name}: (#{versions.map(&:number).join(', ')})"
        end
      end

      ##
      # @param [Hash] options
      # @return [OptionParser]
      #
      def self.option_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: gemirro list [OPTIONS]'
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
