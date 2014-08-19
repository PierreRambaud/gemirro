# -*- coding: utf-8 -*-

module Gemirro
  ##
  # The Indexer class is responsible for downloading useful file directly
  # on the source host, such as specs-*.*.gz, marshal information, etc...
  #
  # @!attribute [r] files
  #  @return [Array]
  # @!attribute [r] quick_marshal_dir
  #  @return [String]
  # @!attribute [r] directory
  #  @return [String]
  # @!attribute [r] dest_directory
  #  @return [String]
  #
  class Indexer < ::Gem::Indexer
    attr_accessor :files, :quick_marshal_dir, :directory, :dest_directory

    ##
    # Generate indicies on the destination directory
    #
    # @return [Array]
    #
    def install_indicies
      verbose = ::Gem.configuration.really_verbose
      say "Downloading index into production dir #{@dest_directory}" if verbose

      files = @files
      files.delete @quick_marshal_dir if files.include? @quick_dir

      if files.include?(@quick_marshal_dir) && !files.include?(@quick_dir)
        files.delete @quick_marshal_dir
        dst_name = File.join(@dest_directory, @quick_marshal_dir_base)
        FileUtils.mkdir_p(File.dirname(dst_name), verbose: verbose)
        FileUtils.rm_rf(dst_name, verbose: verbose)
        FileUtils.mv(@quick_marshal_dir, dst_name,
                     verbose: verbose, force: true)
      end

      files = files.map do |path|
        path.sub(/^#{Regexp.escape @directory}\/?/, '')
      end

      files.each do |file|
        dst_name = File.join @dest_directory, file
        next if File.exist?(dst_name) &&
          (File.mtime(dst_name) >= Time.now - 360)

        resp = Http.get("#{Gemirro.configuration.source.host}/#{file}")
        next unless resp.code == 200
        MirrorFile.new(dst_name).write(resp.body)
      end
    end
  end
end
