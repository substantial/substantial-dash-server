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
    run_event_machine
    client = Faye::Client.new(ENV['BAYEUX_URL'])
    client.add_extension(PublisherAuth::Client.new)
    publication = client.publish(bayeux_channel, json)
    publication.callback do
      Rails.logger.debug("bayeaux published to `#{bayeux_channel}`")
    end
    publication.errback do |error|
      Rails.logger.debug("bayeaux publish failed to `#{bayeux_channel}`: #{error.inspect}")
    end
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

  def run_event_machine
    Thread.new { EM.run } unless EM.reactor_running?
    Thread.pass until EM.reactor_running?
  end
end
