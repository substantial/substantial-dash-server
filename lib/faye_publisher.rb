class FayePublisher
  def bayeux_channel
    raise NotImplementedError, "#bayeux_channel must be implemented in the subclass."
  end

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

  def run_event_machine
    Thread.new { EM.run } unless EM.reactor_running?
    Thread.pass until EM.reactor_running?
  end
end
