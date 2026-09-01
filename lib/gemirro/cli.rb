# frozen_string_literal: true

require File.expand_path('../version', __FILE__)

module Gemirro
  # CLI mode
  module CLI
    ##
    # Names of the commands available, in the order they're listed by
    # `--help`, together with a short description.
    #
    # @return [Hash]
    #
    COMMANDS = {
      'index' => 'Retrieve specs list from source.',
      'init' => 'Sets up a new mirror',
      'list' => 'List available gems.',
      'server' => 'Manage web server',
      'update' => 'Updates the list of Gems'
    }.freeze

    ##
    # Entry point, called from `bin/gemirro`.
    #
    # @param [Array] argv
    #
    def self.run(argv = ARGV)
      $PROGRAM_NAME = 'gemirro'
      command = argv.first
      case command
      when '-v', '--version'
        puts version_information
      when '-h', '--help', nil
        puts usage
      when *COMMANDS.keys
        argv.shift
        require "gemirro/cli/#{command}"
        const_get("#{command.capitalize}Command").run(argv)
      else
        puts "Unknown command: #{command}"
        puts usage
        exit 1
      end
    rescue OptionParser::ParseError => e
      puts e.message
      exit 1
    end

    ##
    # Returns a String containing the top level usage/help banner.
    #
    # @return [String]
    #
    def self.usage
      lines = ['Usage: gemirro [COMMAND] [OPTIONS]', '', 'Options:', '']
      lines << '    -v, --version      Shows the current version'
      lines << '    -h, --help         Display this help message.'
      lines << '' << 'Available commands:' << ''
      COMMANDS.each do |name, description|
        lines << "  #{name.ljust(9)}#{description}"
      end
      lines << '' << 'See `<command> --help` for more information on a specific command.'

      lines.join("\n")
    end

    ##
    # Loads the specified configuration file or displays an error if it doesn't
    # exist.
    #
    # @param [String] config_file
    # @return [Gemirro::Configuration]
    #
    def self.load_configuration(config_file)
      config_file ||= Configuration.default_configuration_file
      config_file   = File.expand_path(config_file, Dir.pwd)
      config_file += '/config.rb' unless config_file.end_with?('.rb') ||
                                         !File.directory?(config_file)

      abort "The configuration file #{config_file} does not exist" unless File.file?(config_file)

      require(config_file)
    end

    ##
    # Returns a String containing some platform/version related information.
    #
    # @return [String]
    #
    def self.version_information
      "gemirro v#{Gemirro::VERSION} on #{RUBY_DESCRIPTION}"
    end

    ##
    # Aborts with an error if the configured destination directory
    # doesn't exist yet.
    #
    # @param [Gemirro::Configuration] config
    #
    def self.ensure_destination!(config)
      return if File.directory?(config.destination)

      config.logger.error("The directory #{config.destination} does not exist")
      abort
    end
  end
end
