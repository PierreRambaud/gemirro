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

    ##
    # Download file from source
    #
    # @param [String] file File path
    # @return [String]
    #
    def download_from_source(file)
      source_host = Gemirro.configuration.source.host
      resp = Http.get("#{source_host}/#{File.basename(file)}")
      return unless resp.code == 200
      resp.body
    end

    ##
    # Build indicies
    #
    # @return [Array]
    #
    def build_indicies
      specs = *map_gems_to_specs(gem_file_list)
      specs.reject! { |s| s.class != ::Gem::Specification }
      ::Gem::Specification.dirs = []
      ::Gem::Specification.all = specs

      build_marshal_gemspecs
      build_modern_indicies if @build_modern

      compress_indicies
    end

    ##
    # Map gems file to specs
    #
    # @param [Array] gems Gems list
    # @return [Array]
    #
    def map_gems_to_specs(gems)
      gems.map do |gemfile|
        if File.size(gemfile) == 0
          Gemirro.configuration.logger
            .warn("Skipping zero-length gem: #{gemfile}")
          next
        end

        begin
          spec = ::Gem::Package.new(gemfile).spec
          spec.loaded_from = gemfile

          # HACK: fuck this shit - borks all tests that use pl1
          if File.basename(gemfile, '.gem') != spec.original_name
            exp = spec.full_name
            exp << " (#{spec.original_name})" if
              spec.original_name != spec.full_name
            msg = "Skipping misnamed gem: #{gemfile} should be named #{exp}"
            Gemirro.configuration.logger.warn(msg)
            next
          end

          abbreviate spec
          sanitize spec

          spec
        rescue SignalException
          msg = 'Received signal, exiting'
          Gemirro.configuration.logger.error(msg)
          raise
        rescue StandardError => e
          msg = ["Unable to process #{gemfile}",
                 "#{e.message} (#{e.class})",
                 "\t#{e.backtrace.join "\n\t"}"].join("\n")
          Gemirro.configuration.logger.debug(msg)
        end
      end.compact
    end
  end
end
