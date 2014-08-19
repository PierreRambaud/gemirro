# -*- coding: utf-8 -*-
require 'spec_helper'
require 'gemirro/source'
require 'gemirro/server'
require 'gemirro/mirror_file'
require 'socket'
require 'mime/types'

#  tests
module Gemirro
  describe 'Server' do
    include FakeFS::SpecHelpers

    it 'should be initialized' do
      Gemirro.configuration.logger.should_receive(:info)
        .once.with('Running server on localhost:2000')
      TCPServer.should_receive(:new).with('localhost', '2000')
      server = Server.new
      expect(server).to be_a(Server)
      expect(server.destination).to eq(Gemirro.configuration.destination)
    end

    it 'should be initialized with host and port' do
      Gemirro.configuration.logger.should_receive(:info)
        .once.with('Running server on gemirro:1337')
      Gemirro.configuration.should_receive(:server_host)
        .at_least(:once).and_return('gemirro')
      Gemirro.configuration.should_receive(:server_port)
        .at_least(:once).and_return('1337')
      TCPServer.should_receive(:new).with('gemirro', '1337')
      server = Server.new
      expect(server).to be_a(Server)
      expect(server.destination).to eq(Gemirro.configuration.destination)
    end

    it 'should return logger' do
      TCPServer.should_receive(:new).once
      Gemirro.configuration.logger.should_receive(:info)
        .once.with('Running server on localhost:2000')
      server = Server.new
      expect(server.logger).to be(Gemirro.configuration.logger)
    end

    it 'should return configuration' do
      TCPServer.should_receive(:new).once
      Gemirro.configuration.logger.should_receive(:info)
        .once.with('Running server on localhost:2000')
      server = Server.new
      expect(server.configuration).to be(Gemirro.configuration)
    end

    it 'should return versions fetcher' do
      TCPServer.should_receive(:new).once
      Gemirro.configuration.logger.should_receive(:info)
        .once.with('Running server on localhost:2000')
      server = Server.new
      server.configuration.source = Source.new(
        'rubygems', 'https://rubygems.org')
      Struct.new('ServerVersionsFetcher', :fetch)

      VersionsFetcher.should_receive(:new)
        .once
        .with(server.configuration.source).and_return(Struct::ServerVersionsFetcher.new(true))
      expect(server.gems_fetcher).to be_a(GemsFetcher)
    end

    it 'should display directory informations' do
      TCPServer.should_receive(:new).once
      Gemirro.configuration.logger.should_receive(:info)
        .once.with('Running server on localhost:2000')
      server = Server.new
      session = MockTCPSocket.new
      FileUtils.mkdir_p('public/directory')
      MirrorFile.new('public/directory/file').write('content')
      expect(server.display_directory(session, 'public/directory'))
        .to eq(['.', '..', 'file'])
      expect(session.output)
        .to eq("HTTP/1.1 200/OK\r\nContent-type:text/html"\
               "\r\n\r\n<a href=\"directory/file\">file</a><br>")
    end
  end

  ##
  # Mock TCP Socket
  class MockTCPSocket
    attr_accessor :response, :output
    def initialize
      @responses = []
      @output    = ''
    end

    def print(line)
      @output << line
    end
  end
end
