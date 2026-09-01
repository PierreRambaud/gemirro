# frozen_string_literal: true

require 'timeout'

module Gemirro
  module CLI
    # `gemirro server` command
    module ServerCommand
      ##
      # @param [Array] argv
      #
      def self.run(argv)
        options = {}
        option_parser(options).parse!(argv)

        config   = load_configuration(options)
        pid_file = pid_file_for(config)

        start(pid_file) if options[:start]
        stop(pid_file) if options[:stop]
        restart(pid_file) if options[:restart]
        status(pid_file) if options[:status]
      end

      ##
      # @param [Hash] options
      # @return [Gemirro::Configuration]
      #
      def self.load_configuration(options)
        Gemirro::CLI.load_configuration(options[:config])
        config = Gemirro.configuration
        config.logger_level = options[:log_level] if options[:log_level]
        Gemirro::CLI.ensure_destination!(config)
        require 'gemirro/server'

        config
      end

      ##
      # @param [Gemirro::Configuration] config
      # @return [String]
      #
      def self.pid_file_for(config)
        File.expand_path(File.join(config.destination, '..', 'gemirro.pid'))
      end

      ##
      # @param [String] pid_file
      # @param [IO] orig_stdout
      #
      def self.create_pid(pid_file, orig_stdout)
        File.write(pid_file, Process.pid.to_s)
      rescue Errno::EACCES
        $stdout.reopen orig_stdout
        puts "Error: Can't write to #{pid_file} - Permission denied"
        exit!
      end

      ##
      # @param [String] pid_file
      #
      def self.destroy_pid(pid_file)
        File.delete(pid_file) if File.exist?(pid_file) && pid(pid_file) == Process.pid
      end

      ##
      # @param [String] pid_file
      # @return [Integer]
      #
      def self.pid(pid_file)
        File.open(pid_file, 'r') do |f|
          return f.gets.to_i
        end
      rescue Errno::ENOENT
        puts "Error: PID File not found #{pid_file}"
      end

      ##
      # @param [String] pid_file
      #
      def self.start(pid_file)
        puts 'Starting...'
        if File.exist?(pid_file) && running?(pid(pid_file))
          puts "Error: #{$PROGRAM_NAME} already running"
          abort
        end

        # Copy stdout because we'll need to reopen it later on
        orig_stdout = $stdout.clone

        Process.daemon if Gemirro::Utils.configuration.server.daemonize
        create_pid(pid_file, orig_stdout)
        $stdout.reopen orig_stdout
        puts "done! (PID is #{pid(pid_file)})\n"
        Gemirro::Server.run!
        destroy_pid(pid_file)
        $stdout.reopen File::NULL, 'a'
      end

      ##
      # @param [String] pid_file
      #
      def self.stop(pid_file)
        process_pid = pid(pid_file)
        return if process_pid.nil?

        begin
          Process.kill('TERM', process_pid)
          Timeout.timeout(30) { sleep 0.1 while running?(process_pid) }
        rescue Errno::ESRCH
          puts "Error: Couldn't find process with PID #{process_pid}"
          exit!
        rescue Timeout::Error
          puts 'timeout while sending TERM signal, sending KILL signal now... '
          Process.kill('KILL', process_pid)
          destroy_pid(pid_file)
        end
        puts 'done!'
      end

      ##
      # @param [String] pid_file
      #
      def self.restart(pid_file)
        stop(pid_file)
        start(pid_file)
      end

      ##
      # @param [String] pid_file
      #
      def self.status(pid_file)
        if running?(pid(pid_file))
          puts "#{$PROGRAM_NAME} is running"
        else
          puts "#{$PROGRAM_NAME} is not running"
          abort
        end
      end

      ##
      # @param [Integer] process_id
      # @return [TrueClass|FalseClass]
      #
      def self.running?(process_id)
        return false if process_id.nil?

        Process.getpgid(process_id.to_i) != -1
      rescue Errno::ESRCH
        false
      end

      ##
      # @param [Hash] options
      # @return [OptionParser]
      #
      def self.option_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: gemirro server [OPTIONS]'
          opts.separator ''
          opts.separator 'Options:'
          opts.separator ''

          opts.on('--start', 'Run web server') { options[:start] = true }
          opts.on('--stop', 'Stop web server') { options[:stop] = true }
          opts.on('--restart', 'Restart web server') { options[:restart] = true }
          opts.on('--status', 'Status of web server') { options[:status] = true }
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
