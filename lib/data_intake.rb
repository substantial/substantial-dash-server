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
    channel = "intake:#{self.class.name.underscore.dasherize}"
    $redis.publish(channel, JSON.generate(object))
  end
end
