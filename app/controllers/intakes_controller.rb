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
      channel_id = params[:id]
      buffer_data = nil
      channel_name = "intake:#{channel_id}"

      begin
        # channel id, when camelized, should match the name of the worker class responsible
        # for processing data for that channel.
        worker_class_name = channel_id.underscore.camelize.constantize

        if worker_class_name < DataIntake
          buffer_data = worker_class_name.read_from_buffer(channel_name)

          stream.write(buffer_data, event: channel_id)

          #Rails.logger.debug("worker class name: #{worker_class_name.inspect}")
          #Rails.logger.debug("Read buffer: #{buffer_data.inspect}")
        end
      rescue NameError => e
        Rails.logger.error("Received a request on the server for a channel that doesn't map to a worker class name.. #{e.inspect}")
      end

      redis.subscribe(channel_name) do |on|
        on.message do |channel, data|
          # data from Redis is already JSON encoded
          stream.write(data, event: channel_id)
        end
      end
    end

  ensure
    redis.quit
  end

end
