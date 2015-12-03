# -*- coding: utf-8 -*-
Gemirro::CLI.options.command 'init' do
  banner 'Usage: gemirro init [DIRECTORY] [OPTIONS]'
  description 'Sets up a new mirror'
  separator "\nOptions:\n"

  run do |_opts, args|
    directory = File.expand_path(args[0] || Dir.pwd)
    template  = Gemirro::Configuration.template_directory

    Dir.mkdir(directory) unless File.directory?(directory)

    Dir.glob("#{template}/**/*", File::FNM_DOTMATCH).each do |file|
      next if ['.', '..'].include?(File.basename(file))
      dest = File.join(directory, file.gsub(/^#{template}/, ''))
      next if File.exist?(dest)
      FileUtils.cp_r(file, dest)
    end

    puts "Initialized empty mirror in #{directory}"
  end
end
