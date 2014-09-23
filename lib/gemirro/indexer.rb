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

      files.each do |path|
        file = path.sub(/^#{Regexp.escape @directory}\/?/, '')
        dst_name = File.join @dest_directory, file
        # next if File.exist?(dst_name) &&
        #   (File.mtime(dst_name) >= Time.now - 360)

        resp = Http.get("#{Gemirro.configuration.source.host}/#{file}")
        next unless resp.code == 200
        source_content = resp.body

        if ["#{@specs_index}.gz",
            "#{@latest_specs_index}.gz",
            "#{@prerelease_specs_index}.gz"].include?(path)
          source_content = Marshal.load(
            Zlib::GzipReader.new(StringIO.new(source_content)).read)
          content = Marshal.load(Zlib::GzipReader.open(path).read)
          new_content = source_content.concat(content).uniq

          Zlib::GzipWriter.open(dst_name) do |io|
            io.write(Marshal.dump(new_content))
          end
        else
          MirrorFile.new(dst_name).write(source_content)
        end

        FileUtils.rm_rf(path)
      end
    end

    def update_gemspecs
      make_temp_directories

      specs_mtime = File.stat(@dest_specs_index).mtime
      newest_mtime = Time.at 0

      updated_gems = gem_file_list.select do |gem|
        gem_mtime = File.stat(gem).mtime
        newest_mtime = gem_mtime if gem_mtime > newest_mtime
        gem_mtime >= specs_mtime
      end

      terminate_interaction(0) if updated_gems.empty?

      specs = map_gems_to_specs updated_gems
      ::Gem::Specification.dirs = []
      ::Gem::Specification.add_specs(*specs)
      files = build_marshal_gemspecs

      files.each do |path|
        file = path.sub(/^#{Regexp.escape @directory}\/?/, '')
        src_name = File.join @directory, file
        dst_name = File.join @dest_directory, file
        FileUtils.mv(src_name, dst_name)
        File.utime newest_mtime, newest_mtime, dst_name
      end
    end
  end
end
