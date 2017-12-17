require 'bowser'
require 'bowser/websocket'
require 'clearwater'

module Clearwater
  class HotLoader
    attr_reader :port, :path

    def self.connect port=nil, deprecated_path=nil, path: '/clearwater_hot_loader'
      if deprecated_path
        warn "[Clearwater::HotLoader] Passing the path as a positional argument is deprecated. Please pass the path as a keyword argument."
      end

      new(port, path: deprecated_path || path).connect
    end

    def initialize port=nil, path: '/clearwater_hot_loader'
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

          # We need to perform the renders synchronously so we can rescue
          # exceptions, but the app registry doesn't give us a way to do that,
          # so we reach in and do this manually. Don't try this at home.
          Clearwater::Application::AppRegistry
            .instance_exec { @apps }
            .each { |app| app.perform_render }
        rescue => e
          error_message = "[Clearwater::HotLoader] Error #{e.class}: #{e.message}"
          `console.error(error_message)`
        end
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
