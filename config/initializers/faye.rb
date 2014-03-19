require 'subscriber_auth'
require 'publisher_auth'
require 'on_subscribe_send_buffer'

Rails.application.config.middleware.use Faye::RackAdapter, extensions: [ 
  SubscriberAuth.new,
  PublisherAuth.new,
  OnSubscribeSendBuffer.new 
]
