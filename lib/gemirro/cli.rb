# frozen_string_literal: true

require File.expand_path('../version', __FILE__)

module Gemirro
  # CLI mode
  module CLI
    ##
    # Hash containing the default Slop options.
    #
    # @return [Hash]
    #
    SLOP_OPTIONS = {
      strict: true,
      help: true,
      banner: 'Usage: gemirro [COMMAND] [OPTIONS]'
    }.freeze

    ##
    # @return [Slop]
    #
    def self.options
      @options ||= default_options
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
    # @return [Slop]
    #
    def self.default_options
      Slop.new(SLOP_OPTIONS.dup) do
        separator "\nOptions:\n"

        on :v, :version, 'Shows the current version' do
          puts CLI.version_information
        end
      end
    end

    ##
    # Returns a String containing some platform/version related information.
    #
    # @return [String]
    #
    def self.version_information
      "gemirro v#{Gemirro::VERSION} on #{RUBY_DESCRIPTION}"
    end
  end
end
