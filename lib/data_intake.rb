class DataIntake
  include Sidekiq::Worker
  include Sidetiq::Schedulable

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
    redis_channel_name = "intake:#{self.class.name.underscore.dasherize}"
    json = JSON.generate(object)
    save_to_buffer(redis_channel_name, json)

    $redis.publish(redis_channel_name, json)
  end

  def save_to_buffer(channel_name, data)
    key_for_buffer = self.class.buffer_key(channel_name)
    $redis.set(key_for_buffer, data)
  end

  def self.read_from_buffer(channel_name)
    key_for_buffer = buffer_key(channel_name)
    $redis.get(key_for_buffer)
  end

  def self.buffer_key(channel_name)
    "#{channel_name}:buffer"
  end

end
