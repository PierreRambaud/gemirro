# -*- coding: utf-8 -*-
Gemirro::CLI.options.command 'init' do
  banner 'Usage: gemirro init [DIRECTORY] [OPTIONS]'
  description 'Sets up a new mirror'
  separator "\nOptions:\n"

  run do |_opts, args|
    directory = File.expand_path(args[0] || Dir.pwd)
    template  = Gemirro::Configuration.template_directory

    Dir.mkdir(directory) unless File.directory?(directory)

    FileUtils.cp_r(File.join(template, '.'), directory)

    puts "Initialized empty mirror in #{directory}"
  end
end
