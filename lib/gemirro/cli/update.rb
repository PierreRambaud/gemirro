Gemirro::CLI.options.command 'update' do
  banner 'Usage: gemirro update [OPTIONS]'
  description 'Updates the list of Gems'
  separator "\nOptions:\n"

  on :c=, :config=, 'Path to the configuration file'
  on :l=, :log_level=, 'Set logger level'

  run do |opts, _args|
    Gemirro::CLI.load_configuration(opts[:c])
    config.logger_level = opts[:l] if opts[:l]

    source = Gemirro.configuration.source
    versions = Gemirro::VersionsFetcher.new(source).fetch
    gems     = Gemirro::GemsFetcher.new(source, versions)

    gems.fetch
  end
end
