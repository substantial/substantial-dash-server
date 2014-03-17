require 'data_intake'
require 'net/http'

class GithubOrgFeedSubstantialSf < DataIntake

  recurrence { minutely(1) }

  def intake
    uri = URI(ENV['INTAKE_GITHUB_API_ORG_FEED_URL'])
    is_ssl = uri.scheme == 'https'
    req = Net::HTTP::Get.new(uri)
    req['Accept'] = 'application/vnd.github.v3+json'
    req['Authorization'] = "token #{ENV['INTAKE_GITHUB_API_TOKEN']}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: is_ssl) do |http|
      http.request(req)
    end

    unless Net::HTTPSuccess===res
      Rails.logger.error "#{self.class} recv'd an unsuccessful response: #{res.inspect}"
      return
    end

    JSON.parse(res.body)
  end
end
