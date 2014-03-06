require 'data_intake'

class IcalendarUpcoming < DataIntake

  EVENT_COUNT_LIMIT = 5

  recurrence { minutely(15) }

  def intake
    uri = URI(ENV['INTAKE_GOOGLE_ICALENDAR_URL'])
    is_ssl = uri.scheme == 'https'
    req = Net::HTTP::Get.new(uri)

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: is_ssl) do |http|
      http.request(req)
    end

    unless res.code == '200'
      Rails.logger.error "#{self.class} recv'd an unsuccessful response: #{res.inspect}"
      return
    end

    calendar = parse_calendar(res.body)
    events = upcoming_events(calendar)

    export(events[0...EVENT_COUNT_LIMIT])
  end

  def export(ri_events)
    ri_events.map do |event|
      {
        summary: event.summary,
        description: event.description,
        location: event.location,
        starts_at: event.dtstart,
        ends_at: event.dtend,
        organizer: event.organizer
      }
    end
  end

  def parse_calendar(ics_data)
    cals = RiCal.parse_string(ics_data.to_s)
    cals.first
  end

  # Given an RiCal calendar, return its events in chronological order,
  # including up to `EVENT_COUNT_LIMIT` recurrences of each 
  # recurring event.
  #
  def upcoming_events(calendar)
    raise(ArgumentError, "A calendar is required.") unless 
      calendar.respond_to?(:events)
    events = []
    now=Time.now
    calendar.events.each do |event|
      if event.recurrence_id
        # Do not collect explicit recurrences, instead
        # enumerate them with RiCal in the next `elsif` clause.
      elsif event.recurs?
        events.concat(
          event.occurrences(
            starting: now, 
            count: EVENT_COUNT_LIMIT
          )
        )
      else
        events << event
      end
    end
    events = events.select {|event| event.dtstart > now }
    events = events.sort_by {|event| event.dtstart }
    events
  end
end
