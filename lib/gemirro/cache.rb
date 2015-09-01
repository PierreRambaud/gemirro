# -*- coding: utf-8 -*-
module Gemirro
  ##
  # The Cache class contains all method to store marshal informations
  # into files.
  #
  # @!attribute [r] root_path
  #  @return [String]
  #
  class Cache
    attr_reader :root_path

    ##
    # Initialize cache root path
    #
    # @param [String] path
    #
    def initialize(path)
      @root_path = path
      create_root_path
    end

    ##
    # Create root path
    #
    def create_root_path
      FileUtils.mkdir_p(@root_path)
    end

    ##
    # Flush cache directory
    #
    def flush
      FileUtils.rm_rf(@root_path)
      create_root_path
    end

    ##
    # Flush key
    #
    # @param [String] key
    #
    def flush_key(key)
      path = key_path(key2hash(key))
      FileUtils.rm_f(path)
    end

    ##
    # Cache data
    #
    # @param [String] key
    #
    # @return [Mixed]
    #
    def cache(key)
      key_hash = key2hash(key)
      read(key_hash) || (write(key_hash, yield) if block_given?)
    end

    private

    ##
    # Convert key to hash
    #
    # @param [String] key
    #
    # @return [String]
    #
    def key2hash(key)
      Digest::MD5.hexdigest(key)
    end

    ##
    # Path from key hash
    #
    # @param [String] key_hash
    #
    # @return [String]
    #
    def key_path(key_hash)
      File.join(@root_path, key_hash)
    end

    ##
    # Read cache
    #
    # @param [String] key_hash
    #
    # @return [Mixed]
    #
    def read(key_hash)
      path = key_path(key_hash)
      Marshal.load(File.open(path)) if File.exist?(path)
    end

    ##
    # write cache
    #
    # @param [String] key_hash
    # @param [Mixed] value
    #
    # @return [Mixed]
    #
    def write(key_hash, value)
      File.open(key_path(key_hash), 'wb') do |f|
        Marshal.dump(value, f)
      end

      value
    end
  end
end
