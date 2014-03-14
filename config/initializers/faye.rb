require 'subscriber_auth'
require 'publisher_auth'

Rails.application.config.middleware.use Faye::RackAdapter, extensions: [ SubscriberAuth.new, PublisherAuth.new ]
