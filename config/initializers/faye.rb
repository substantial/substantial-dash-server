require 'subscriber_auth'
require 'publisher_auth'
require 'on_subscribe_send_buffer'

Rails.application.config.middleware.use Faye::RackAdapter, {
  timeout: 28,
  engine: {
    type: Faye::Redis,
    uri: REDIS_URL,
    namespace: "#{REDIS_NAMESPACE}-faye"
  },
  extensions: [ 
    SubscriberAuth.new,
    PublisherAuth.new,
    OnSubscribeSendBuffer.new 
  ]
}
