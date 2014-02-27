require "server_sent_event_stream"

class DashboardsController < ApplicationController
  include ActionController::Live

  def broadcast
    # SSE expects the `text/event-stream` content type
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Origin'] = 'http://0.0.0.0:8000'

    # This stream will remain open until the client closes or disconnects.
    ServerSentEventStream.new(response.stream).write_and_close do |stream|
      $redis.subscribe("dashboard:#{params[:id]}") do |on|
        on.message do |channel, data|
          stream.write(data)
        end
      end
    end
  end
end
