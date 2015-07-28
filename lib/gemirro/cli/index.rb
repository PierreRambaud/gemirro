# -*- coding: utf-8 -*-
Gemirro::CLI.options.command 'index' do
  banner 'Usage: gemirro index [OPTIONS]'
  description 'Retrieve specs list from source.'
  separator "\nOptions:\n"

  on :c=, :config=, 'Path to the configuration file'
  on :u, :update, 'Update only'

  run do |opts, _args|
    Gemirro::CLI.load_configuration(opts[:c])
    config = Gemirro.configuration

    unless File.directory?(config.destination)
      config.logger.error("The directory #{config.destination} does not exist")
      abort
    end

    indexer    = Gemirro::Indexer.new(config.destination)
    indexer.ui = Gem::SilentUI.new

    config.logger.info('Generating indexes')
    indexer.generate_index if opts[:u].nil?
    indexer.update_index unless opts[:u].nil?
  end
end
