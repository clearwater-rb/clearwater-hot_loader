# Clearwater::HotLoader

A complete solution for re-rendering a Clearwater app in development without a full-page reload.

## Installation

In your `Gemfile`:

```ruby
# This gem is only useful in the development environment
gem 'clearwater-hot_loader', group: :development
```

Then run `bundle` to get it installed.

## Usage

In order to get hot-loading working, we need to connect three parts:

1. The filesystem monitor to trigger changes
2. WebSocket server to notify the client about changes
3. WebSocket client to receive the push from the server

The examples in this README will have examples for Rails, but we only rely on Rack.

### Filesystem Monitor

You kick off the filesystem monitor by running `Clearwater::HotLoader.start`.

For a Rails app, simply add that command to the end of your `config/environments/development.rb` file to ensure it only gets run in development.

For Rack apps that aren't based on Rails, you can add this to your `config.ru` file (above the line beginning with `run`):

```ruby
if ENV['RACK_ENV'] == 'development'
  Clearwater::HotLoader.start
end
```

### WebSocket Server

The client needs to know what to connect to in order to listen for changes, so we need to add an endpoint to our web app to make this happen. How you do this depends entirely on which back-end framework you're using, but most Rack-based frameworks (including Rails) have a way to mount another Rack app as the handler for an endpoint.

_Note: You want to ensure you're only mounting it in development._

In Rails, add this to your `config/routes.rb` file:

```ruby
mount Clearwater::HotLoader, at: '/clearwater_hot_loader' if Rails.env.development?
```

The `Clearwater::HotLoader` module contains a Rack server which will handle a WebSocket connection. The filesystem monitor notifies the WebSocket server when files have changed.

### WebSocket Client

The WebSocket client listens for updates from the server and executes them, updating the Ruby environment running inside the browser, and then re-renders your Clearwater app. If you have multiple Clearwater apps running on the page, it will re-render all of them.

To connect to the server, simply add this to the top of your Clearwater app:

```ruby
require 'clearwater/hot_loader'
Clearwater::HotLoader.connect port
```

Simply replace `port` with the port number on which your app is running. It will be the same port on which your web app is running. For example, if you usually open `localhost:3000` to load your web app in the browser, you'll want to connect to port 3000.

## Caveats

- Hot loading involves patching classes and objects that are already loaded. If your code is executing as if being run for the first time, existing app state may be clobbered with fresh state.
- `require` statements are ignored for various reasons:
  - Reloading all dependencies is nearly always unnecessary
  - The Opal environment is not designed to be idempotent. Reloading it may clobber the one already loaded.
- Because of that, if you add an outside dependency, you will likely need to refresh the page.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/clearwater-rb/clearwater-hot_loader).

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.
