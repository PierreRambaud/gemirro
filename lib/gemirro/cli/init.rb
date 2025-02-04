# frozen_string_literal: true

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
        next if File.exist?(dest) && dest !~ /gemirro.css/

        FileUtils.cp_r(file, dest)
      end
    end

    # make sure index updates blank local specs
    ['specs.4.8', 'latest_specs.4.8', 'prerelease_specs.4.8'].each do |s|
      File.utime(Time.at(0), Time.at(0), File.join(directory, 'public', s))
    end

    puts "Initialized empty mirror in #{directory}"
  end
end
