class SubscriberAuth
  KEY_PREFIX = 'api-read-key:'

  def incoming(message, callback)
    if message['channel'] != '/meta/subscribe'
      return callback.call(message)
    end

    api_key = message['ext'] && message['ext']['apiKey']
    unless api_key
      Rails.logger.debug("SubscriberAuth halted without API key")
      message['error'] = 'API key is required'
      callback.call(message)
      return
    end

    auth_data = $redis.hgetall("#{KEY_PREFIX}#{api_key}")
    if auth_data && !auth_data.empty?
      Rails.logger.info("SubscriberAuth succeeded: #{auth_data.inspect}")
    else
      Rails.logger.info("SubscriberAuth failed for API key: #{api_key.inspect}")
      message['error'] = 'Unauthorized'
      callback.call(message)
      return
    end

    callback.call(message)

  rescue => e
    Rails.logger.error("#{e.class} in #{self.class}: #{e.message} at #{e.backtrace.first} for #{message.inspect}")
    raise
  end
end
