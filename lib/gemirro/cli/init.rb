# -*- coding: utf-8 -*-
Gemirro::CLI.options.command 'init' do
  banner 'Usage: gemirro init [DIRECTORY] [OPTIONS]'
  description 'Sets up a new mirror'
  separator "\nOptions:\n"
  on :force, 'Force overwrite'

  run do |opts, args|
    directory = File.expand_path(args[0] || Dir.pwd)
    template  = Gemirro::Configuration.template_directory

    Dir.mkdir(directory) unless File.directory?(directory)

    if opts[:force]
      FileUtils.cp_r(File.join(template, '.'), directory)
    else
      Dir.glob("#{template}/**/*", File::FNM_DOTMATCH).each do |file|
        next if ['.', '..'].include?(File.basename(file))
        dest = File.join(directory, file.gsub(/^#{template}/, ''))
        next if File.exist?(dest)
        FileUtils.cp_r(file, dest)
      end
    end

    puts "Initialized empty mirror in #{directory}"
  end
end
