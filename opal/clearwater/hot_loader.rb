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
      @app = InitialApp.new
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
      match, scheme, host, port, = *Bowser.window.location.href.match(%r{(https?)://([^:/]+)(?:\:(\d+))?/?([^\?]*)})
      port = @port if @port
      socket_url = "ws#{'s' if scheme == 'https'}://#{host}#{":#{port}" if port}#{path}"
      @socket = Bowser::WebSocket.new(socket_url)

      @socket.on :open do
        @app.render
      end

      @socket.on :message do |msg|
        data = msg.data
        if data.key? :js
          begin
            %x{ eval(#{data[:js]}) }

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
        elsif data.key? :css
          id = "clearwater-hot-loader-style-#{data[:css][:filename].gsub(/\W/, '-')}"
          style = Bowser.document["##{id}"] || Bowser.document.create_element(:style)
          new_element = style.id.empty?
          style.id = id
          style.text_content = data[:css][:body]

          Bowser.document.head.append style if new_element
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

    class InitialApp
      def render
      end
    end
  end
end
