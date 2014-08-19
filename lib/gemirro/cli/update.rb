# -*- coding: utf-8 -*-
Gemirro::CLI.options.command 'update' do
  banner 'Usage: gemirro update [OPTIONS]'
  description 'Updates the list of Gems'
  separator "\nOptions:\n"

  on :c=, :config=, 'Path to the configuration file'

  run do |opts, _args|
    Gemirro::CLI.load_configuration(opts[:c])

    source = Gemirro.configuration.source
    versions = Gemirro::VersionsFetcher.new(source).fetch
    gems     = Gemirro::GemsFetcher.new(source, versions)

    gems.fetch
  end
end
