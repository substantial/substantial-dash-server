# Substantial Dash server [![Build Status](https://travis-ci.org/substantial/substantial-dash-server.png)](https://travis-ci.org/substantial/substantial-dash-server)

**An early work-in-progress** to visualize realtime events, statuses, and key performance indicators.

Designed to broadcast data to [Substantial Dash client](https://github.com/substantial/substantial-dash-client).

## Tech

* [Ruby on Rails 4](http://rubyonrails.org)
* [Bayeux/Faye events](http://faye.jcoglan.com): publish & subscribe to data streams
* [Redis](http://redis.io): work queue, scheduling, and key/value persistence
* [Sidekiq](http://mperham.github.com/sidekiq/): asynchronous job processing
* [OmniAuth](https://github.com/intridea/omniauth): user authentication

## Development

### Requirements

* [Ruby 2.1.1](https://www.ruby-lang.org/en/installation/) installed
* `gem install bundler`
* `brew install direnv` & [add the hook for your shell](http://direnv.net/)
* `brew install redis` & follow resulting directions to start the server or add launcher

### Install
```sh
    git clone git@github.com:substantial/substantial-dash-server.git
    cd substantial-dash-server/
    bin/setup-dev-env
```

Configure your specific Dash's **bayeux_url** in *config/environment.rb* and child *config/environments/\**. The default config should work for local development; each production Dash will require its own unique *config/environments/production.rb*.

### Testing

Run the test suite:

```sh
bundle exec rspec
```

### Boot-up

Start the server at http://0.0.0.0:8001

```sh
bundle exec puma -p 8001 --config config/puma.rb
```

...and in another terminal, the background workers:

```sh
bundle exec sidekiq
```
