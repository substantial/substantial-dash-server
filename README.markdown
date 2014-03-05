# Substantial Dash server

**An early work-in-progress** to visualize realtime events, statuses, and key performance indicators.

Designed to broadcast data to [Substantial Dash client](https://github.com/substantial/substantial-dash-client).

## Tech

* [Ruby on Rails 4](http://rubyonrails.org)
* [Server Sent Events](http://www.html5rocks.com/en/tutorials/eventsource/basics/): streaming dashboard updates
* [Redis](http://redis.io/): publish/subscribe & data persistence
* [Sidekiq](http://mperham.github.com/sidekiq/): asynchronous job processing

## Development

### Requirements

* [Rubinius 2.2.5](http://rubini.us/) installed
* `gem install bundler`
* `brew install direnv` & [add the hook for your shell](http://direnv.net/)
* `brew install redis` & follow resulting directions to start the server or add launcher

### Install

    git clone git@github.com:substantial/substantial-dash-server.git
    cd substantial-dash-server/
    bundle install --path vendor/bundle

Set-up the **.envrc** file containing auth keys:

    export INTAKE_GITHUB_API_ORG_FEED_URL=https://api.github.com/...
    export INTAKE_GITHUB_API_TOKEN=XXXXX

Then, execute `direnv allow`

### Testing

Run the test suite:

    bundle exec rspec

### Boot-up
    
Start the server at http://0.0.0.0:8001
    
    bundle exec puma -p 8001 --config config/puma.rb

**Note this Rails development server does not auto-reload code,** because the class-reloading seems to causes the Redis connections to silently drop.

...and in another terminal, the background workers:

    bundle exec sidekiq
