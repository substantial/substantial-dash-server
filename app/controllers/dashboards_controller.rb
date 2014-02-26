require "server_sent_event_stream"

class DashboardsController < ApplicationController
  include ActionController::Live

  def broadcast
    # SSE expects the `text/event-stream` content type
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Origin'] = 'http://0.0.0.0:8000'

    sse_stream = ServerSentEventStream.new(response.stream)

    begin
      loop do
        sse_stream.write({ :time => Time.now })
        sleep 1
      end
    rescue IOError
      # When the client disconnects, we'll get an IOError on write
    ensure
      sse_stream.close
    end
  end
end
