# This is the main configuration file for your RubyGems mirror. Here you can
# change settings such as the location to store Gem files in and what source
# and Gems you'd like to mirror at start.
Gemirro.configuration.configure do
  # Define sinatra environment
  environment :production

  # The directory to store indexing information as well as the Gem files in.
  destination File.expand_path('../public', __FILE__)

  # If you're in development mode your probably want to switch to a debug
  # logging level.
  logger.level = Logger::INFO

  # If you want to run your server on a specific host and port, you must
  # change the following parameters (server_host and server_port).
  #
  # server.host 'localhost'
  # server.port '2000'

  # If you don't want the server to run daemonized, uncomment the following
  # server.daemonize false
  server.access_log File.expand_path('../logs/access.log', __FILE__)
  server.error_log File.expand_path('../logs/error.log', __FILE__)

  # If you don't want to generate indexes after each fetched gem.
  #
  # update_on_fetch false

  # If you don't want to fetch gem if file does not exists when
  # running gemirro server.
  #
  # fetch_gem false

  # You must define a source which where gems will be downloaded.
  # All gem in the block will be downloaded with the update command.
  # Other gems will be downloaded with the server.
  define_source 'rubygems', 'http://rubygems.org' do
    gem 'rack', '>= 1.0.0'
  end
end
