require 'spec_helper'

module Clearwater
  describe HotLoader do
    let(:loader) do
      Class.new {
        include HotLoader

        public :sockets, :add_socket, :remove_socket
      }.new
    end

    describe 'adding websockets' do
      let(:fake_socket) { Object.new }

      it 'adds sockets' do
        loader.add_socket fake_socket
        expect(loader.sockets).to include fake_socket
      end

      it 'removes websockets' do
        loader.add_socket fake_socket
        loader.remove_socket fake_socket

        expect(loader.sockets).to be_empty
      end
    end
  end
end
