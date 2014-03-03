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
      redis.subscribe("intake:#{params[:id]}") do |on|
        on.message do |channel, data|
          # data from Redis is already JSON encoded
          stream.write(data, event: params[:id])
        end
      end
    end

  ensure
    redis.quit
  end

end
