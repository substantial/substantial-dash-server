require 'data_intake'
require 'net/http'

class BeerAtWeWork < DataIntake

  recurrence { minutely(1) }

  def intake
    data = get_beer_data

    data.sort! { |x,y| y['floor'] <=> x['floor'] }

    Rails.logger.debug(data.inspect)
    data
  end

  def get_beer_data
    env_var_name = 'INTAKE_BEER_AT_WE_WORK_DATA_URL'
    data_url = ENV[env_var_name]

    if data_url.nil?
      Rails.logger.error "Environment variable '#{env_var_name}' is not specified"
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
