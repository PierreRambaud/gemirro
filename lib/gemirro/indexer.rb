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
  # @!attribute [r] updated_gems
  #  @return [Array]
  #
  class Indexer < ::Gem::Indexer
    attr_accessor(:files,
                  :quick_marshal_dir,
                  :directory,
                  :dest_directory,
                  :only_origin,
                  :updated_gems)

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
    # Generate indices on the destination directory
    #
    def install_indices
      install_indicies
    end

    ##
    # Generate indicies on the destination directory
    #
    # @return [Array]
    #
    def install_indicies
      Utils.logger
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
        src_name = File.join(@directory, file)
        dst_name = File.join(@dest_directory, file)

        if ["#{@specs_index}.gz",
            "#{@latest_specs_index}.gz",
            "#{@prerelease_specs_index}.gz"].include?(path)
          res = build_zlib_file(file, src_name, dst_name, true)
          next unless res
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
      Utils.logger.info("Download from source: #{file}")
      resp = Http.get("#{source_host}/#{File.basename(file)}")
      return unless resp.code == 200
      resp.body
    end

    ##
    # Build indices
    #
    # @return [Array]
    #
    def build_indices
      build_indicies
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

      if ::Gem::VERSION >= '2.5.0'
        build_marshal_gemspecs specs
        build_modern_indices specs if @build_modern
        compress_indices
      else
        build_marshal_gemspecs
        build_modern_indicies if @build_modern
        compress_indicies
      end
    end

    ##
    # Map gems file to specs
    #
    # @param [Array] gems Gems list
    # @return [Array]
    #
    def map_gems_to_specs(gems)
      gems.map.with_index do |gemfile, index|
        # rubocop:disable Metrics/LineLength
        Utils.logger.info("[#{index + 1}/#{gems.size}]: Processing #{gemfile.split('/')[-1]}")
        # rubocop:enable Metrics/LineLength

        if File.size(gemfile) == 0
          Utils.logger.warn("Skipping zero-length gem: #{gemfile}")
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
            Utils.logger.warn(msg)
            next
          end

          if ::Gem::VERSION >= '2.5.0'
            spec.abbreviate
            spec.sanitize
          else
            abbreviate spec
            sanitize spec
          end

          spec
        rescue SignalException
          msg = 'Received signal, exiting'
          Utils.logger.error(msg)
          raise
        rescue StandardError => e
          msg = ["Unable to process #{gemfile}",
                 "#{e.message} (#{e.class})",
                 "\t#{e.backtrace.join "\n\t"}"].join("\n")
          Utils.logger.debug(msg)
        end
      end.compact
    end

    def update_index
      make_temp_directories

      specs_mtime = File.stat(@dest_specs_index).mtime
      newest_mtime = Time.at(0)

      @updated_gems = gem_file_list.select do |gem|
        gem_mtime = File.stat(gem).mtime
        newest_mtime = gem_mtime if gem_mtime > newest_mtime
        gem_mtime > specs_mtime
      end

      if @updated_gems.empty?
        Utils.logger.info('No new gems')
        terminate_interaction(0)
      end

      specs = map_gems_to_specs(@updated_gems)
      prerelease, released = specs.partition { |s| s.version.prerelease? }

      ::Gem::Specification.dirs = []
      ::Gem::Specification.all = *specs
      if ::Gem::VERSION >= '2.5.0'
        files = build_marshal_gemspecs specs
      else
        files = build_marshal_gemspecs
      end

      ::Gem.time('Updated indexes') do
        update_specs_index(released, @dest_specs_index, @specs_index)
        update_specs_index(released,
                           @dest_latest_specs_index,
                           @latest_specs_index)
        update_specs_index(prerelease,
                           @dest_prerelease_specs_index,
                           @prerelease_specs_index)
      end

      if ::Gem::VERSION >= '2.5.0'
        compress_indices
      else
        compress_indicies
      end

      Utils.logger.info("Updating production dir #{@dest_directory}") if verbose
      files << @specs_index
      files << "#{@specs_index}.gz"
      files << @latest_specs_index
      files << "#{@latest_specs_index}.gz"
      files << @prerelease_specs_index
      files << "#{@prerelease_specs_index}.gz"

      files.each do |path|
        file = path.sub(%r{^#{Regexp.escape @directory}/?}, '')
        src_name = File.join(@directory, file)
        dst_name = File.join(@dest_directory, file)

        if ["#{@specs_index}.gz",
            "#{@latest_specs_index}.gz",
            "#{@prerelease_specs_index}.gz"].include?(path)
          res = build_zlib_file(file, src_name, dst_name)
          next unless res
        else
          FileUtils.mv(src_name,
                       dst_name,
                       verbose: verbose,
                       force: true)
        end

        File.utime(newest_mtime, newest_mtime, dst_name)
      end
    end

    def build_zlib_file(file, src_name, dst_name, from_source = false)
      content = Marshal.load(Zlib::GzipReader.open(src_name).read)
      create_zlib_file("#{dst_name}.orig", content)

      return false if @only_origin

      if from_source
        source_content = download_from_source(file)
        source_content = Marshal.load(Zlib::GzipReader
                                        .new(StringIO
                                               .new(source_content)).read)
      else
        source_content = Marshal.load(Zlib::GzipReader.open(dst_name).read)
      end

      return false if source_content.nil?
      new_content = source_content.concat(content).uniq
      create_zlib_file(dst_name, new_content)
    end

    def create_zlib_file(dst_name, content)
      temp_file = Tempfile.new('gemirro')

      Zlib::GzipWriter.open(temp_file.path) do |io|
        io.write(Marshal.dump(content))
      end

      FileUtils.mv(temp_file.path,
                   dst_name,
                   verbose: verbose,
                   force: true)
      Utils.cache.flush_key(File.basename(dst_name))
    end

    def verbose
      @verbose ||= ::Gem.configuration.really_verbose
    end
  end
end
