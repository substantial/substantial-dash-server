# An IO stream wrapper to produce HTML5 Server Sent Events:
# http://www.html5rocks.com/en/tutorials/eventsource/basics/
#
class ServerSentEventStream

  # Instantiate with the IO object that should receive the output.
  #
  # For Rails 4 controllers that `include ActionController::Live`, the
  # IO should be `response.stream`.
  #
  def initialize(io)
    unless io.respond_to?(:write)
      raise ArgumentError, "Argument must act like IO; got #{io.inspect}"
    end
    @io = io
  end

  # Perform #write(s) in the passed block.
  #
  def write_and_close
    yield(self) if block_given?
  rescue IOError
    # Client disconnect; write raises IOError.
  ensure
    close
  end

  # Serializes the object to JSON, outputting to the IO.
  #
  # Meta keys include:
  #   * `id` lets the browser keep track of the last event fired
  #   * `retry` milliseconds to wait before trying to reconnect
  #   * `event` names the event; browser can listen for it specifically
  #
  def write(object, meta={})
    meta.each do |k,v|
      @io.write "#{k}: #{v}\n"
    end
    @io.write "data: #{JSON.dump(object)}\n\n"
  end

  def close
    @io.close
  end
end
