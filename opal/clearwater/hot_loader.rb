require 'bowser'
require 'bowser/websocket'
require 'clearwater'

module Clearwater
  class HotLoader
    attr_reader :port, :path

    def self.connect port=3000, path='/clearwater_hot_loader'
      new(port, path).connect
    end

    def initialize port, path='/clearwater_hot_loader'
      @port = port
      @path = path
    end

    def connect
      @socket = Bowser::WebSocket.new("ws://localhost:#{port}#{path}")

      @socket.on :message do |msg|
        %x{ eval(msg.native.data) }
        Clearwater::Application.render
      end

      @socket.on :close do
        Bowser.window.delay 1 do
          connect
        end
      end

      self
    end
  end
end
