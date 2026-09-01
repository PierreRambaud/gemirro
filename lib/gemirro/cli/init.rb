# frozen_string_literal: true

module Gemirro
  module CLI
    # `gemirro init` command
    module InitCommand
      ##
      # @param [Array] argv
      #
      def self.run(argv)
        options = {}
        option_parser(options).parse!(argv)

        directory = File.expand_path(argv[0] || Dir.pwd)
        template  = Gemirro::Configuration.template_directory

        Dir.mkdir(directory) unless File.directory?(directory)

        if options[:force]
          FileUtils.cp_r(File.join(template, '.'), directory)
        else
          Dir.glob("#{template}/**/*", File::FNM_DOTMATCH).each do |file|
            next if ['.', '..'].include?(File.basename(file))

            dest = File.join(directory, file.gsub(/^#{template}/, ''))
            next if File.exist?(dest) && dest !~ /gemirro.css/

            FileUtils.cp_r(file, dest)
          end
        end

        puts "Initialized empty mirror in #{directory}"
      end

      ##
      # @param [Hash] options
      # @return [OptionParser]
      #
      def self.option_parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: gemirro init [DIRECTORY] [OPTIONS]'
          opts.separator ''
          opts.separator 'Options:'
          opts.separator ''

          opts.on('--force', 'Force overwrite') { options[:force] = true }
          opts.on('-h', '--help', 'Display this help message.') do
            puts opts
            exit
          end
        end
      end
    end
  end
end
