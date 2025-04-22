# frozen_string_literal: true

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
    attr_accessor(
      :files,
      :quick_marshal_dir,
      :directory,
      :dest_directory,
      :only_origin,
      :updated_gems
    )

    ##
    # Create an indexer that will index the gems in +directory+.
    #
    # @param [String] directory Destination directory
    # @param [Hash] options Indexer options
    # @return [Array]
    ##
    def initialize(options = {})
      require 'fileutils'
      require 'tmpdir'
      require 'zlib'
      require 'builder/xchar'
      require 'compact_index'

      options.merge!({ build_modern: false })

      @dest_directory = Gemirro.configuration.destination
      @directory =
        File.join(Dir.tmpdir, "gem_generate_index_#{rand(1_000_000_000)}")

      marshal_name = "Marshal.#{::Gem.marshal_version}"

      @master_index =
        File.join(@directory, 'yaml')
      @marshal_index =
        File.join(@directory, marshal_name)

      @quick_dir = File.join(@directory, 'quick')
      @quick_marshal_dir =
        File.join(@quick_dir, marshal_name)
      @quick_marshal_dir_base =
        File.join(@dest_directory, 'quick', marshal_name) # FIX: UGH

      @quick_index =
        File.join(@quick_dir, 'index')
      @latest_index =
        File.join(@quick_dir, 'latest_index')

      @specs_index =
        File.join(@directory, "specs.#{::Gem.marshal_version}")
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
      @infos_dir =
        File.join(@dest_directory, 'info')
      @api_v1_dependencies_dir =
        File.join(@dest_directory, 'api', 'v1', 'dependencies')

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
        FileUtils.mkdir_p(File.dirname(@quick_marshal_dir_base), verbose: verbose)
        FileUtils.rm_rf(@quick_marshal_dir_base, verbose: verbose)
        FileUtils.mv(@quick_marshal_dir, @quick_marshal_dir_base, verbose: verbose, force: true)
      end

      files.each do |path|
        file = path.sub(%r{^#{Regexp.escape @directory}/?}, '')

        if ["#{@specs_index}.gz",
            "#{@latest_specs_index}.gz",
            "#{@prerelease_specs_index}.gz"].include?(path)
          res = build_zlib_file(file, File.join(@directory, file), File.join(@dest_directory, file), true)
          next unless res
        else
          source_content = download_from_source(file)
          next if source_content.nil?

          MirrorFile.new(File.join(@dest_directory, file)).write(source_content)
        end

        FileUtils.rm_rf(path)
      end
    end

    ##
    # Download file from source (example: rubygems.org)
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
      specs.select! { |s| s.instance_of?(::Gem::Specification) }
      ::Gem::Specification.dirs = []
      ::Gem::Specification.all = specs

      build_marshal_gemspecs(specs)
      #compress_indices

      build_compact_index_names
      build_compact_index_infos(specs)
      build_compact_index_versions(specs)
    end

    ##
    # Cache compact_index endpoint /names
    # Report all gems with versions available. Does not require opening spec files.
    #
    # @return nil
    #
    def build_compact_index_names
      Utils.logger.info('[1/1]: Caching /names')
      FileUtils.rm_rf(Dir.glob(File.join(@dest_directory, 'names*.list')))

      gem_name_list = Dir.glob('*.gem', base: File.join(@dest_directory, 'gems')).collect do |x|
        x.sub(/-\d+(\.\d+)*(\.[a-zA-Z\d]+)*([-_a-zA-Z\d]+)?\.gem/, '')
      end.uniq.sort!

      Tempfile.create('names.list') do |f|
        f.write CompactIndex.names(gem_name_list).to_s
        f.rewind
        FileUtils.cp(
          f.path,
          File.join(
            @dest_directory,
            "names.#{Digest::MD5.file(f.path).hexdigest}.#{Digest::SHA256.file(f.path).hexdigest}.list"
          ),
          verbose: verbose
        )
      end

      nil
    end

    ##
    # Cache compact_index endpoint /versions
    #
    # @param [Array] specs Gems list
    # @param [Boolean] partial Is gem list an update or a full index
    # @return nil
    #
    def build_compact_index_versions(specs, partial = false)
      Utils.logger.info('[1/1]: Caching /versions')

      cg =
        specs
        .sort_by(&:name)
        .group_by(&:name)
        .collect do |name, gem_versions|
          gem_versions =
            gem_versions.sort do |a, b|
              a.version <=> b.version
            end

          info_file = Dir.glob(File.join(@infos_dir, "#{name}.*.*.list")).last

          throw "Info file for #{name} not found" unless info_file

          info_file_checksum = info_file.split('.', -4)[-3]

          CompactIndex::Gem.new(
            name,
            gem_versions.collect do |y|
              CompactIndex::GemVersion.new(
                y.version.to_s,
                y.platform,
                nil,
                info_file_checksum
              )
            end
          )
        end

      Tempfile.create('versions.list') do |f|
        previous_versions_file = Dir.glob(File.join(@dest_directory, 'versions*.list')).last

        if partial && previous_versions_file
          versions_file = CompactIndex::VersionsFile.new(previous_versions_file)
        else
          versions_file = CompactIndex::VersionsFile.new(f.path)
          f.write format('created_at: %s', Time.now.utc.iso8601)
          f.write "\n---\n"
        end

        f.write CompactIndex.versions(versions_file, cg)
        f.rewind

        FileUtils.rm_rf(Dir.glob(File.join(@dest_directory, 'versions*.list')))

        FileUtils.cp(
          f.path,
          File.join(
            @dest_directory,
            "versions.#{Digest::MD5.file(f.path).hexdigest}.#{Digest::SHA256.file(f.path).hexdigest}.list"
          ),
          verbose: verbose
        )
      end

      nil
    end

    ##
    # Cache compact_index endpoint /info/[gemname]
    #
    # @param [Array] specs Gems list
    # @param [Boolean] partial Is gem list an update or a full index
    # @return nil
    #
    def build_compact_index_infos(specs, partial = false)
      FileUtils.mkdir_p(@infos_dir)

      if partial
        specs.collect(&:name).uniq do |name|
          FileUtils.rm_rf(Dir.glob(File.join(@infos_dir, "#{name}.*.*.list")))
        end
      else
        FileUtils.rm_rf(Dir.glob(File.join(@infos_dir, '*.list')))
      end

      grouped_specs = specs.sort_by(&:name).group_by(&:name)
      grouped_specs.each_with_index do |(name, gem_versions), index|
        Utils.logger.info("[#{index + 1}/#{grouped_specs.size}]: Caching /info/#{name}")

        gem_versions =
          gem_versions.sort do |a, b|
            a.version <=> b.version
          end

        versions =
          Parallel.map(gem_versions, in_threads: Utils.configuration.update_thread_count) do |spec|
            deps =
              spec
              .dependencies
              .select { |d| d.type == :runtime }
              .sort_by(&:name)
              .collect do |dependency|
                CompactIndex::Dependency.new(
                  dependency.name,
                  dependency.requirement.to_s
                )
              end

            CompactIndex::GemVersion.new(
              spec.version,
              spec.platform,
              Digest::SHA256.file(spec.loaded_from).hexdigest,
              nil,
              deps,
              spec.required_ruby_version.to_s,
              spec.required_rubygems_version.to_s
            )
          end

        Tempfile.create("info_#{name}.list") do |f|
          f.write CompactIndex.info(versions).to_s
          f.rewind

          FileUtils.cp(
            f.path,
            File.join(
              @infos_dir,
              "#{name}.#{Digest::MD5.file(f.path).hexdigest}.#{Digest::SHA256.file(f.path).hexdigest}.list"
            ),
            verbose: verbose
          )
        end
      end

      nil
    end

    ##
    # Map gems file to specs
    #
    # @param [Array] gems Gems list
    # @return [Array]
    #
    def map_gems_to_specs(gems)
      results = []

      Parallel.each_with_index(gems, in_threads: Utils.configuration.update_thread_count) do |gemfile, index|
        Utils.logger.info("[#{index + 1}/#{gems.size}]: Processing #{gemfile.split('/')[-1]}")
        if File.empty?(gemfile)
          Utils.logger.warn("Skipping zero-length gem: #{gemfile}")
          next
        end

        begin
          begin
            spec =
              if ::Gem::Package.respond_to? :open
                ::Gem::Package.open(File.open(gemfile, 'rb'), 'r', &:metadata)
              else
                ::Gem::Package.new(gemfile).spec
              end
          rescue NotImplementedError
            next
          end

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

          version = spec.version.version
          unless version =~ /^\d+(\.\d+)?(\.\d+)?.*/
            msg = "Skipping gem #{spec.full_name} - invalid version #{version}"
            Utils.logger.warn(msg)
            next
          end

          spec.abbreviate
          spec.sanitize

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

        results[index] = spec
      end

      # nils can result from insert by index
      results.compact
    end

    ##
    # Handle `index --update`, detecting changed files and file lists.
    #
    # @return nil
    #
    def update_index
      make_temp_directories

      present_gemfiles = Dir.glob('*.gem', base: File.join(@dest_directory, 'gems'))
      indexed_gemfiles = Dir.glob('*.gemspec.rz', base: @quick_marshal_dir_base).collect { |x| x.gsub(/spec.rz$/, '') }

      @updated_gems = []


      # detect files manually added to public/gems
      @updated_gems += (present_gemfiles - indexed_gemfiles).collect { |x| File.join(@dest_directory, 'gems', x) }
      # detect files manually deleted from public/gems
      @updated_gems += (indexed_gemfiles - present_gemfiles).collect { |x| File.join(@dest_directory, 'gems', x) }



      versions_mtime =
        begin
          File.stat(Dir.glob(File.join(@dest_directory, 'versions*.list')).last).mtime
        rescue StandardError
          Time.at(0)
        end
      newest_mtime = Time.at(0)

      # files that have been replaced
      @updated_gems +=
        gem_file_list.select do |gem|
          gem_mtime = File.stat(gem).mtime
          newest_mtime = gem_mtime if gem_mtime > newest_mtime
          gem_mtime > versions_mtime
        end

      @updated_gems.uniq!

      if @updated_gems.empty?
        Utils.logger.info('No new gems')
        terminate_interaction(0)
      end

      specs = map_gems_to_specs(@updated_gems)

      # specs only includes latest discovered files.
      # /info/[gemname] can not be rebuilt
      # incrementally, so retrive specs for all versions of these gems.
      gem_name_updates = specs.collect(&:name).uniq
      u2 =
        Dir.glob(File.join(File.join(@dest_directory, 'gems'), '*.gem')).select do |possibility|
          gem_name_updates.any? { |updated| File.basename(possibility) =~ /^#{updated}-\d/ }
        end

      Utils.logger.info('Reloading for /info/[gemname]')
      version_specs = map_gems_to_specs(u2)

      #prerelease, released = specs.partition { |s| s.version.prerelease? }

      ::Gem::Specification.dirs = []
      ::Gem::Specification.all = *specs
      files =
        build_marshal_gemspecs specs

      #::Gem.time('Updated indexes') do
      #  update_specs_index(
      #    released,
      #    @dest_specs_index,
      #    @specs_index
      #  )
      #  update_specs_index(
      #    released,
      #    @dest_latest_specs_index,
      #    @latest_specs_index
      #  )
      #  update_specs_index(
      #    prerelease,
      #    @dest_prerelease_specs_index,
      #    @prerelease_specs_index
      #  )
      #end

      #compress_indices

      # build_api_v1_dependencies(version_specs, true)

        build_compact_index_names
        build_compact_index_infos(version_specs, true)
        build_compact_index_versions(specs, true)

=begin
      Utils.logger.info("Updating production dir #{@dest_directory}") if verbose
      files << @specs_index
      files << "#{@specs_index}.gz"
      files << @latest_specs_index
      files << "#{@latest_specs_index}.gz"
      files << @prerelease_specs_index
      files << "#{@prerelease_specs_index}.gz"

      files.each do |path|
        file = path.sub(%r{^#{Regexp.escape @directory}/?}, '')

        if ["#{@specs_index}.gz", "#{@latest_specs_index}.gz", "#{@prerelease_specs_index}.gz"].include?(path)
          res = build_zlib_file(file, File.join(@directory, file), File.join(@dest_directory, file))
          next unless res
        else
          FileUtils.mv(
            File.join(@directory, file),
            File.join(@dest_directory, file),
            verbose: verbose,
            force: true
          )
        end

        File.utime(newest_mtime, newest_mtime, File.join(@dest_directory, file))
      end
=end
    end


    def build_zlib_file(file, src_name, dst_name, from_source = false)
      content = Marshal.load(Zlib::GzipReader.open(src_name).read)
      create_zlib_file("#{dst_name}.local", content)

      return false if @only_origin

      if from_source
        source_content = download_from_source(file)
        source_content = Marshal.load(
          Zlib::GzipReader.new(
            StringIO.new(source_content)
          ).read
        )
      else
        source_content = Marshal.load(Zlib::GzipReader.open(dst_name).read)
      end

      return false if source_content.nil?

      new_content = source_content.concat(content).uniq
      create_zlib_file(dst_name, new_content)
    end

    def create_zlib_file(dst_name, content)
      Tempfile.create(File.basename(dst_name)) do |f|
        gzf = Zlib::GzipWriter.new(f)
        gzf.write(Marshal.dump(content))
        gzf.close

        FileUtils.cp(
          f.path,
          dst_name,
          verbose: verbose
        )
      end
    end

    def verbose
      @verbose ||= ::Gem.configuration.really_verbose
    end
  end
end
