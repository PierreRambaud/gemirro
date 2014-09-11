# -*- coding: utf-8 -*-
Gemirro::CLI.options.command 'server' do
  banner 'Usage: gemirro server [OPTIONS]'
  description 'Run web server'
  separator "\nOptions:\n"

  on :c=, :config=, 'Path to the configuration file'

  run do |opts, _args|
    Gemirro::CLI.load_configuration(opts[:c])
    config = Gemirro.configuration
    unless File.directory?(config.destination)
      config.logger.error("The directory #{config.destination} does not exist")
      abort
    end

    require 'gemirro/server'
    Gemirro::Server.run!
  end
end
