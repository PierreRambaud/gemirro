# frozen_string_literal: true

Gemirro::CLI.options.command 'index' do
  banner 'Usage: gemirro index [OPTIONS]'
  description 'Retrieve specs list from source.'
  separator "\nOptions:\n"

  on :c=, :config=, 'Path to the configuration file'
  on :l=, :log_level=, 'Set logger level'
  on :u, :update, 'Update only'

  run do |opts, _args|
    Gemirro::CLI.load_configuration(opts[:c])
    config = Gemirro.configuration
    config.logger_level = opts[:l] if opts[:l]

    unless File.directory?(config.destination)
      config.logger.error("The directory #{config.destination} does not exist")
      abort
    end

    indexer    = Gemirro::Indexer.new(config.destination)
    indexer.ui = Gem::SilentUI.new

    if opts[:u]
      if File.exist?(File.join(config.destination, 'specs.4.8'))
        config.logger.info('Generating index updates')
        indexer.update_index
      else
        config.logger.info('Generating indexes')
        indexer.generate_index
      end
    else
      config.logger.info('Generating indexes')
      indexer.generate_index
    end
  end
end
