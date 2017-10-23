# Configuration
module Gemirro
  ##
  # @return [Gemirro::Configuration]
  #
  def self.configuration
    default_config = {
      server: {
        access_log: '/tmp/gemirro.access.log',
        error_log: '/tmp/gemirro.access.log'
      },

      update_on_fetch: true,
      fetch_gem: true
    }
    @configuration ||= Configuration.new(default_config)
  end

  ##
  # Configuration class used for storing data about a mirror such as the
  # destination directory, source, ignored Gems, etc.
  #
  class Configuration < Confstruct::Configuration
    attr_accessor :source
    attr_writer :logger

    LOGGER_LEVEL = {
      'debug' => Logger::DEBUG,
      'warning' => Logger::WARN,
      'info' => Logger::INFO,
      'unknown' => Logger::UNKNOWN,
      'error' => Logger::ERROR,
      'fatal' => Logger::FATAL
    }.freeze

    ##
    # Returns the logger
    #
    # @return [Logger]
    #
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    ##
    # Set log level
    #
    # @param [string]
    #
    # @return [Logger]
    #
    def logger_level=(level)
      logger.level = LOGGER_LEVEL[level] if LOGGER_LEVEL.key?(level)
      logger
    end

    ##
    # Returns the template path to init directory
    #
    # @return [String]
    #
    def self.template_directory
      File.expand_path('../../../template', __FILE__)
    end

    ##
    # Returns the views path to render templates
    #
    # @return [String]
    #
    def self.views_directory
      File.expand_path('../../../views', __FILE__)
    end

    ##
    # Returns default configuration file path
    #
    # @return [String]
    #
    def self.default_configuration_file
      File.expand_path('config.rb', Dir.pwd)
    end

    ##
    # Returns the name of the directory that contains the quick
    # specification files.
    #
    # @return [String]
    #
    def self.marshal_identifier
      "Marshal.#{marshal_version}"
    end

    ##
    # Returns the name of the file that contains an index of all the versions.
    #
    # @return [String]
    #
    def self.versions_file
      "specs.#{marshal_version}.gz"
    end

    ##
    # Returns the name of the file that contains an index
    # of all the prerelease versions.
    #
    # @return [String]
    #
    def self.prerelease_versions_file
      "prerelease_specs.#{marshal_version}.gz"
    end

    ##
    # Returns a String containing the Marshal version.
    #
    # @return [String]
    #
    def self.marshal_version
      "#{Marshal::MAJOR_VERSION}.#{Marshal::MINOR_VERSION}"
    end

    ##
    # Return mirror directory
    #
    # @return [Gemirro::MirrorDirectory]
    #
    def mirror_gems_directory
      @mirror_gems_directory ||= MirrorDirectory.new(gems_directory)
    end

    ##
    # Returns gems directory
    #
    # @return [String]
    #
    def gems_directory
      File.join(destination.to_s, 'gems')
    end

    ##
    # Return mirror directory
    #
    # @return [Gemirro::MirrorDirectory]
    #
    def mirror_gemspecs_directory
      @mirror_gemspecs_directory ||= MirrorDirectory.new(gemspecs_directory)
    end

    ##
    # Returns gems directory
    #
    # @return [String]
    #
    def gemspecs_directory
      File.join(destination.to_s, 'quick', self.class.marshal_identifier)
    end

    ##
    # Returns a Hash containing various Gems to ignore and their versions.
    #
    # @return [Hash]
    #
    def ignored_gems
      @ignored_gems ||= Hash.new { |hash, key| hash[key] = [] }
    end

    ##
    # Adds a Gem to the list of Gems to ignore.
    #
    # @param [String] name
    # @param [String] version
    #
    def ignore_gem(name, version)
      ignored_gems[name] ||= []
      ignored_gems[name] << version
    end

    ##
    # Checks if a Gem should be ignored.
    #
    # @param [String] name
    # @param [String] version
    # @return [TrueClass|FalseClass]
    #
    def ignore_gem?(name, version)
      ignored_gems[name].include?(version)
    end

    ##
    # Define the source to mirror.
    #
    # @param [String] name
    # @param [String] url
    # @param [Proc] block
    #
    def define_source(name, url, &block)
      source = Source.new(name, url)
      source.instance_eval(&block)

      @source = source
    end
  end
end
