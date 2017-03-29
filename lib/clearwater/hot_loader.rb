require 'opal'
require 'clearwater/hot_loader/server'
require 'clearwater/hot_loader/file_listener'
require 'clearwater/hot_loader/configuration'
require 'set'

module Clearwater
  module HotLoader
    module_function

    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def call env
      server.call env
    end

    def server
      @server ||= Server.new
    end

    def start
      @listeners = configuration.directories.map { |dir|
        puts "[Clearwater::HotLoader] Monitoring #{dir}"
        FileListener.new(dir) do |filename|
          begin
            puts "[Clearwater::HotLoader] Compiling #{filename}..."
            code = server.compile_file(filename)
          rescue SyntaxError => e
            puts "ONOES! #{e.class} - #{e.message}"
          end

          puts "[Clearwater::HotLoader] Hot-loading #{filename}..."
          sockets.each do |ws|
            ws.send code
          end
        end
      }
      @listeners.each(&:start)
      puts "[Clearwater::HotLoader] started."
    end

    def sockets
      @sockets ||= Set.new
    end

    def add_socket socket
      sockets << socket
      self
    end

    def remove_socket socket
      sockets.delete socket
      self
    end
  end
end

Opal.append_path File.expand_path('../../../opal', __FILE__)
