class DataIntake
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  sidekiq_options :retry => 1

  # Schedule a recurrence in subclasses (commented out in superclass):
  #
  #     recurrence { minutely(5) }
  #

  # Download & aggregate data from an external source.
  #
  # Override per-subclass.
  #
  # Return the object to be published to the Redis #channels.
  #
  def intake
    raise NotImplementedError, "#intake must be implemented in a subclass."
  end

  # Sidekiq async method.
  #
  def perform
    publish(intake)
  end

  # Push the object (serialized to JSON) out to all subscribers.
  #
  def publish(object)
    json = JSON.generate(object)
    save_to_buffer(json)

    EM.run do
      client = Faye::Client.new(Rails.application.config.bayeux_url)
      client.add_extension(PublisherAuth::Client.new)
      publication = client.publish(bayeux_channel, json)
      publication.callback do
        Rails.logger.debug("bayeaux published to `#{bayeux_channel}`")
        EM.stop_event_loop
      end
      publication.errback do |error|
        Rails.logger.debug("bayeaux publish failed to `#{bayeux_channel}`: #{error.inspect}")
        EM.stop_event_loop
      end
    end
  end

  def save_to_buffer(data)
    $redis.set(redis_buffer_key, data)
  end

  def self.read_from_buffer
    $redis.get(redis_buffer_key)
  end

  def self.channel_name
    name.underscore.dasherize
  end

  def self.redis_channel_name(alt_name=nil)
    name = alt_name || channel_name
    # Literal subscription names are prefixed by "/", so for 
    # convenience remove it here.
    name = name.gsub(/^\//, '')
    "intake:#{name}"
  end

  def self.redis_buffer_key(alt_name=nil)
    "#{redis_channel_name(alt_name)}:buffer"
  end

  def channel_name
    self.class.channel_name
  end

  def redis_channel_name
    self.class.redis_channel_name
  end

  def redis_buffer_key
    self.class.redis_buffer_key
  end

  def bayeux_channel
    "/#{channel_name}"
  end

end
