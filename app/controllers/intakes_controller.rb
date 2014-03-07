require "server_sent_event_stream"

class IntakesController < ApplicationController
  include ActionController::Live

  def subscribe
    # SSE expects the `text/event-stream` content type
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Origin'] = 'http://0.0.0.0:8000'

    # Each "Live" request is on a separate thread, so needs a new connection.
    redis = Redis::Namespace.new(REDIS_NAMESPACE, :redis => Redis.new)

    # This stream will remain open until the client closes or disconnects.
    # Dropped connections will remain open until the next write is attempted.
    ServerSentEventStream.new(response.stream).write_and_close do |stream|
      client_channel_id = params[:id]
      worker_class = NilClass
      redis_channel_name = "intake:#{client_channel_id}"

      begin
        # channel id, when camelized, should match the name of the worker class responsible
        # for processing data for that channel.
        worker_class = client_channel_id.underscore.camelize.constantize
      rescue NameError => e
        Rails.logger.error("Received a request on the server for a channel that doesn't map to a worker class name.. #{e.inspect}")
      end

      if worker_class.ancestors.include?(DataIntake) && !(worker_class == DataIntake)

        # first push out data in the buffer so that client immediately sees something
        buffer_data = worker_class.read_from_buffer(redis_channel_name)
        stream.write(buffer_data, event: client_channel_id)

        # then subscribe to future events
        redis.subscribe(redis_channel_name) do |on|
          on.message do |channel, data|
            # data from Redis is already JSON encoded
            stream.write(data, event: client_channel_id)
          end
        end
      end
    end

  ensure
    redis.quit
  end

end
