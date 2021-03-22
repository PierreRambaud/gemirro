# frozen_string_literal: true

Gemirro::CLI.options.command 'server' do
  banner 'Usage: gemirro server [OPTIONS]'
  description 'Manage web server'
  separator "\nOptions:\n"

  on :start, 'Run web server'
  on :stop, 'Stop web server'
  on :restart, 'Restart web server'
  on :status, 'Status of web server'
  on :c=, :config=, 'Path to the configuration file'
  on :l=, :log_level=, 'Set logger level'

  @pid_file = nil

  run do |opts, _args|
    load_configuration(opts)
    start if opts[:start]
    stop if opts[:stop]
    restart if opts[:restart]
    status if opts[:status]
  end

  def load_configuration(opts)
    Gemirro::CLI.load_configuration(opts[:c])
    config = Gemirro.configuration
    config.logger_level = opts[:l] if opts[:l]
    unless File.directory?(config.destination)
      config.logger.error("The directory #{config.destination} does not exist")
      abort
    end

    @pid_file = File.expand_path(File.join(config.destination,
                                           '..',
                                           'gemirro.pid'))
    require 'gemirro/server'
  end

  # Copy stdout because we'll need to reopen it later on
  @orig_stdout = $stdout.clone
  $PROGRAM_NAME = 'gemirro'

  def create_pid
    File.open(@pid_file, 'w') do |f|
      f.write(Process.pid.to_s)
    end
  rescue Errno::EACCES
    $stdout.reopen @orig_stdout
    puts "Error: Can't write to #{@pid_file} - Permission denied"
    exit!
  end

  def destroy_pid
    File.delete(@pid_file) if File.exist?(@pid_file) && pid == Process.pid
  end

  def pid
    File.open(@pid_file, 'r') do |f|
      return f.gets.to_i
    end
  rescue Errno::ENOENT
    puts "Error: PID File not found #{@pid_file}"
  end

  def start
    puts 'Starting...'
    if File.exist?(@pid_file) && running?(pid)
      puts "Error: #{$PROGRAM_NAME} already running"
      abort
    end

    Process.daemon if Gemirro::Utils.configuration.server.daemonize
    create_pid
    $stdout.reopen @orig_stdout
    puts "done! (PID is #{pid})\n"
    Gemirro::Server.run!
    destroy_pid
    $stdout.reopen '/dev/null', 'a'
  end

  def stop
    process_pid = pid
    return if process_pid.nil?

    begin
      Process.kill('TERM', process_pid)
      Timeout.timeout(30) { sleep 0.1 while running?(process_pid) }
    rescue Errno::ESRCH
      puts "Error: Couldn't find process with PID #{process_pid}"
      exit!
    rescue Timeout::Error
      puts 'timeout while sending TERM signal, sending KILL signal now... '
      Process.kill('KILL', process_pid)
      destroy_pid
    end
    puts 'done!'
  end

  def restart
    stop
    start
  end

  def status
    if running?(pid)
      puts "#{$PROGRAM_NAME} is running"
    else
      puts "#{$PROGRAM_NAME} is not running"
      abort
    end
  end

  def running?(process_id)
    return false if process_id.nil?

    Process.getpgid(process_id.to_i) != -1
  rescue Errno::ESRCH
    false
  end
end
