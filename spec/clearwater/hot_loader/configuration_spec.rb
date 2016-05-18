require 'clearwater/hot_loader/configuration'

module Clearwater
  module HotLoader
    describe Configuration do
      describe :directories do
        it 'defaults to Rails and Roda asset directories' do
          FileUtils.mkdir_p 'assets/js'
          FileUtils.mkdir_p 'app/assets/javascripts'
          config = Configuration.new

          expect(config.directories).to include 'assets/js', 'app/assets/javascripts'
          FileUtils.rm_rf 'assets'
          FileUtils.rm_rf 'app'
        end

        it 'takes a list of directories' do
          directories = [
            'opal/clearwater', # a directory that exists
            'lol',             # and one that doesn't
          ]

          config = Configuration.new(
            directories: directories,
          )

          expect(config.directories).to eq ['opal/clearwater']
        end
      end
    end
  end
end
