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
  # @!attribute [r] only_origin
  #  @return [Boolean]
  #
  class Indexer < ::Gem::Indexer
    attr_accessor(:files,
                  :quick_marshal_dir,
                  :directory,
                  :dest_directory,
                  :only_origin)

    ##
    # Create an indexer that will index the gems in +directory+.
    #
    # @param [String] directory Destination directory
    # @param [Hash] options Indexer options
    # @return [Array]
    ##
    def initialize(directory, options = {})
      require 'fileutils'
      require 'tmpdir'
      require 'zlib'

      unless defined?(Builder::XChar)
        fail 'Gem::Indexer requires that the XML Builder ' \
        'library be installed:' \
        "\n\tgem install builder"
      end

      options = { build_modern: true }.merge options

      @build_modern = options[:build_modern]

      @dest_directory = directory
      @directory = File.join(Dir.tmpdir,
                             "gem_generate_index_#{rand(1_000_000_000)}")

      marshal_name = "Marshal.#{::Gem.marshal_version}"

      @master_index = File.join @directory, 'yaml'
      @marshal_index = File.join @directory, marshal_name

      @quick_dir = File.join @directory, 'quick'
      @quick_marshal_dir = File.join @quick_dir, marshal_name
      @quick_marshal_dir_base = File.join 'quick', marshal_name # FIX: UGH

      @quick_index = File.join @quick_dir, 'index'
      @latest_index = File.join @quick_dir, 'latest_index'

      @specs_index = File.join @directory, "specs.#{::Gem.marshal_version}"
      @latest_specs_index =
        File.join(@directory, "latest_specs.#{::Gem.marshal_version}")
      @prerelease_specs_index =
        File.join(@directory, "prerelease_specs.#{::Gem.marshal_version}")
      @dest_specs_index =
        File.join(@dest_directory, "specs.#{::Gem.marshal_version}")
      @dest_latest_specs_index =
        File.join(@dest_directory, "latest_specs.#{::Gem.marshal_version}")
      @dest_prerelease_specs_index =
        File.join(@dest_directory, "prerelease_specs.#{::Gem.marshal_version}")

      @files = []
    end

    ##
    # Generate indicies on the destination directory
    #
    # @return [Array]
    #
    def install_indicies
      verbose = ::Gem.configuration.really_verbose
      Gemirro.configuration.logger
        .debug("Downloading index into production dir #{@dest_directory}")

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

      files.each do |path|
        file = path.sub(%r{^#{Regexp.escape @directory}/?}, '')
        dst_name = File.join @dest_directory, file

        if ["#{@specs_index}.gz",
            "#{@latest_specs_index}.gz",
            "#{@prerelease_specs_index}.gz"].include?(path)

          content = Marshal.load(Zlib::GzipReader.open(path).read)
          Zlib::GzipWriter.open("#{dst_name}.orig") do |io|
            io.write(Marshal.dump(content))
          end

          unless @only_origin
            source_content = download_from_source(file)
            next if source_content.nil?
            source_content = Marshal.load(Zlib::GzipReader
                                            .new(StringIO
                                                   .new(source_content)).read)
            new_content = source_content.concat(content).uniq

            Zlib::GzipWriter.open(dst_name) do |io|
              io.write(Marshal.dump(new_content))
            end
          end
        else
          source_content = download_from_source(file)
          next if source_content.nil?
          MirrorFile.new(dst_name).write(source_content)
        end

        FileUtils.rm_rf(path)
      end
    end

    def download_from_source(file)
      source_host = Gemirro.configuration.source.host
      resp = Http.get("#{source_host}/#{File.basename(file)}")
      return unless resp.code == 200
      resp.body
    end

    def build_indicies
      ::Gem::Specification.dirs = []
      ::Gem::Specification.all = *map_gems_to_specs(gem_file_list)

      build_marshal_gemspecs
      build_modern_indicies if @build_modern

      compress_indicies
    end
  end
end
