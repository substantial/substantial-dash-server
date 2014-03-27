source 'https://rubygems.org'
ruby "2.1.1"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.3'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :production do
  # Heroku plug-in
  gem 'rails_12factor'
end

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

group :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'timecop'
  gem 'em-rspec', git: 'https://github.com/substantial/em-rspec.git'
end

# Multi-threaded, concurrent app server.
gem 'puma'
# Bidirectional, async client server (WebSockets)
gem 'faye'
# Pub/Sub system, and persistence.
gem 'redis'
gem 'redis-namespace'
# Async processing.
gem 'sidekiq'
gem 'sinatra', '>= 1.3.0', :require => nil
# Recurring job scheduler.
gem 'sidetiq'
# iCalendar / *.ics parser
gem 'ri_cal'
# OAuth2 authentication
gem 'omniauth'
gem 'omniauth-google-apps'
gem 'openid-store-redis'

# Redis-backed session & cache stores.
gem 'redis-rails'

# GitHub hypermedia API
gem 'octokit', '~> 2.0.0'
# ETag-aware response caching
gem 'faraday-http-cache'

# Process runner used at Heroku
gem 'foreman'
# Prevent requests running over Heroku's timeout
gem 'rack-timeout'
