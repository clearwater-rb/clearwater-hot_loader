module Clearwater
  module HotLoader
    class Configuration
      attr_reader :directories

      def initialize attributes={}
        candidate_directories = Dir[
          *%w(
            app/assets/javascripts
            app/assets/stylesheets
            assets/js
            assets/css
          )
        ]
        self.directories = candidate_directories

        attributes.each do |attr, value|
          public_send "#{attr}=", value
        end
      end

      def directories= directories
        @directories = Array(directories).select { |f|
          File.directory?(f)
        }
      end
    end
  end
end
