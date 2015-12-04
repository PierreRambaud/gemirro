# -*- coding: utf-8 -*-
Gemirro::CLI.options.command 'list' do
  banner 'Usage: gemirro list [OPTIONS]'
  description 'List available gems.'
  separator "\nOptions:\n"

  on :c=, :config=, 'Path to the configuration file'

  run do |opts, _args|
    Gemirro::CLI.load_configuration(opts[:c])
    config = Gemirro.configuration

    unless File.directory?(config.destination)
      config.logger.error("The directory #{config.destination} does not exist")
      abort
    end

    gems = Gemirro::Utils.gems_collection.group_by(&:name).sort
    gems.each do |name, versions|
      puts "#{name}: (#{versions.map(&:number).join(', ')})"
    end
  end
end
