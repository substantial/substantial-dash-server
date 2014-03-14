require 'subscriber_auth'
Rails.application.config.middleware.use Faye::RackAdapter, extensions: [ SubscriberAuth.new ]
