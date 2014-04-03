require 'faye_channel_buffer'

# Faye extension that buffers the current message so that it can be resent 
# later to new subscribers in OnSubscribeSendBuffer.
#
class OnPublishSetBuffer
  def incoming(message, callback)
    channel = message['channel']

    # Bayeux protocol "meta" and Dash "personal" messages are not buffered.
    if channel =~ %r{^/(meta|personal)/.+}
      return callback.call(message)
    end

    $redis.set(FayeChannelBuffer.key(channel), message['data'], ex: 1.hour)

    callback.call(message)

  rescue => e
    Rails.logger.error("#{e.class} in #{self.class}: #{e.message} at #{e.backtrace.first} for #{message.inspect}")
    raise
  end
end
