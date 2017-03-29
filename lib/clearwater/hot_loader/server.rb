require 'opal'
require 'faye/websocket'

module Clearwater
  module HotLoader
    class Server
      include Faye

      attr_reader :hot_loader

      def initialize hot_loader=HotLoader
        @hot_loader = hot_loader
      end

      def call env
        if WebSocket.websocket? env
          ws = WebSocket.new(env)

          ws.on :open do
            hot_loader.add_socket ws
          end

          ws.on :close do
            hot_loader.remove_socket ws
          end

          ws.rack_response
        else
          [200, { 'Content-Type' => 'text/plain' }, ['Websockets only, please.']]
        end
      end

      def compile_file filename
        code = File.read(filename)

        if filename.end_with? '.rb'
          Opal.compile(code)
        elsif filename.end_with? '.js'
          code
        else
          ''
        end
      rescue => e
        ''
      end
    end
  end
end
