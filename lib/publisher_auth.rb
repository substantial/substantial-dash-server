# Faye extension to authenticate publishing.
#
class PublisherAuth

  def added(server)
    raise(ArgumentError, "Environment variable `BAYEUX_PUBLISH_KEY` must be set.") if
      ENV['BAYEUX_PUBLISH_KEY'].blank?
  end

  def incoming(message, callback)
    channel = message['channel']

    if channel =~ %r{^/meta/.+}
      return callback.call(message)
    end

    # Delete the API key so that all subscribers don't receive it.
    api_key = message['ext'] && message['ext'].delete('apiKey')

    if api_key != ENV['BAYEUX_PUBLISH_KEY']
      Rails.logger.info("PublisherAuth failed for #{channel}: #{api_key.inspect}")
      message['error'] = 'Unauthorized'
      callback.call(message)
      return
    end

    callback.call(message)
  end

  # Faye extension to allow publishing to the server implementing PublisherAuth.
  #
  class Client
    def outgoing(message, callback)
      channel = message['channel']

      if channel =~ %r{^/meta/.+}
        return callback.call(message)
      end

      message['ext'] ||= {}
      message['ext']['apiKey'] = ENV['BAYEUX_PUBLISH_KEY']

      callback.call(message)
    end
  end
end
