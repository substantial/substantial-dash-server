require 'faye_channel_buffer'
require 'publisher_auth'

# Faye extension that immediately pushes the most recent event from 
# the channel to new subscribers on their personal channel.
#
class OnSubscribeSendBuffer
  attr_accessor :client

  def added(server)
    self.client = Faye::Client.new(server)
    client.add_extension(PublisherAuth::Client.new)
  end

  def incoming(message, callback)
    subscription = message['subscription']
    # Ignore any messages that are not subscribe requests, and that are already a personal channel.
    should_ignore = message['channel'] != '/meta/subscribe' || 
      !subscription || subscription.index('/personal') == 0
    return callback.call(message) if should_ignore

    # An API key is required
    api_key = message['ext'] && message['ext']['apiKey']
    unless api_key
      Rails.logger.debug("#{self.class} skipped for #{subscription} without API key")
      callback.call(message)
      return
    end

    # Verify existence of API key
    auth_data = $redis.hgetall("#{SubscriberAuth::KEY_PREFIX}#{api_key}")
    if !auth_data || auth_data.empty?
      Rails.logger.debug("#{self.class} skipped for #{subscription} because API key was not found")
      callback.call(message)
      return
    end

    # Publish last buffered channel data to the client's personal channel
    personal_channel = bayeux_personal_channel(api_key, subscription)
    key = FayeChannelBuffer.key(subscription)
    if buffered_data = $redis.get(key)
      publication = client.publish(personal_channel, buffered_data)
      publication.callback do
        Rails.logger.debug("bayeaux published to `#{personal_channel}`")
      end
      publication.errback do |error|
        Rails.logger.error("bayeaux publish failed to `#{personal_channel}`: #{error.inspect}")
      end
    end

    callback.call(message)

  rescue => e
    Rails.logger.error("#{e.class} in #{self.class}: #{e.message} at #{e.backtrace.first} for #{message.inspect}")
    raise
  end

  def bayeux_personal_channel(api_key, public_channel)
    "/personal/#{api_key}#{public_channel}"
  end
end
