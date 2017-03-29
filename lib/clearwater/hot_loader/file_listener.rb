require 'listen'

module Clearwater
  module HotLoader
    class FileListener
      def initialize directory, &block
        @directory = directory

        @listener = Listen.to(directory) do |modified, added, removed|
          (modified + added).uniq.each do |file|
            block.call(file)
          end
        end
      end

      def start
        @listener.start
      end
    end
  end
end
