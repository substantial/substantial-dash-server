# Substantial Dash server

**An early work-in-progress** to visualize realtime events, statuses, and key performance indicators.

Designed to broadcast data to [Substantial Dash client](https://github.com/substantial/substantial-dash-client).

## Tech

* [Ruby on Rails 4](http://rubyonrails.org)
* [Server Sent Events](http://www.html5rocks.com/en/tutorials/eventsource/basics/): streaming dashboard updates

## Development

### Requirements

* [Ruby 2.0](https://www.ruby-lang.org/en/installation/) installed
* `gem install bundler`

### Boot-up

    git clone git@github.com:substantial/substantial-dash-server.git
    cd substantial-dash-server/
    bundle install --path vendor/bundle

Run the test suite:

    bundle exec rspec
    
Start the auto-reloading dev server at http://0.0.0.0:8001
    
    bundle exec rails server -p 8001

