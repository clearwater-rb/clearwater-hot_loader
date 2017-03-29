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
      Bowser.window.animation_frame do
        div = Bowser.document.create_element('div')
        Bowser.document.body.append div
        @app = Clearwater::Application.new(
          component: ConnectionIndicator.new(self),
          element: div,
        )
        @app.call
      end
    end

    def connect
      @socket = Bowser::WebSocket.new("ws://localhost:#{port}#{path}")

      @socket.on :open do
        @app.render
      end

      @socket.on :message do |msg|
        begin
          %x{ eval(msg.native.data) }
        rescue => e
          error_message = "[Clearwater::HotLoader] Error #{e.class}: #{e.message}"
          `console.error(error_message)`
        end
        Clearwater::Application.render
      end

      @socket.on :close do
        @app.render
        Bowser.window.delay 0.5 do
          connect
        end
      end

      self
    end

    def connected?
      @socket.connected?
    end

    class ConnectionIndicator
      include Clearwater::Component

      def initialize loader
        @loader = loader
      end

      def render
        div({ style: style }, [
          connection_status,
        ])
      end

      def connection_status
        span([
          "Hot Loader: ",
          @loader.connected? ? 'Connected' : 'Disconnected',
        ])
      end

      def style
        connected = @loader.connected?
        {
          position: :fixed,
          bottom: 0,
          right: 0,
          background_color: connected ? :green : :red,
          color: :white,
        }
      end
    end
  end
end
