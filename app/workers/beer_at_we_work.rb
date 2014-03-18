require 'data_intake'
require 'net/http'

class BeerAtWeWork < DataIntake

  recurrence { secondly(10) }

  def intake
    data = get_beer_data

    Rails.logger.debug(data.inspect)
    data
  end


  def get_beer_data()
    data_url = ENV['INTAKE_BEER_LOCATOR_DATA_URL']

    if data_url.nil?
      Rails.logger.error "Environment variable 'INTAKE_BEER_LOCATOR_DATA_URL' is not specified"
    end

    uri = URI(data_url)

    is_ssl = uri.scheme == 'https'
    req = Net::HTTP::Get.new(uri)
    req['Accept'] = 'text/plain'

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: is_ssl) do |http|
      http.request(req)
    end

    unless Net::HTTPSuccess===res
      Rails.logger.error "#{self.class} received an unsuccessful response: #{res.inspect}"
      return
    end

    JSON.parse(res.body)
  end
end
