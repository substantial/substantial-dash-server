require 'faye_publisher'

class DataIntake < FayePublisher
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

  def self.channel_name
    name.underscore.dasherize
  end

  def channel_name
    self.class.channel_name
  end

  def bayeux_channel
    "/#{channel_name}"
  end
end
