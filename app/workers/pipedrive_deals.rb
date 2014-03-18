require 'data_intake'
require 'net/http'

class PipedriveDeals < DataIntake

  recurrence { minutely(1) }

  def intake
    filter_names = ENV['INTAKE_PIPEDRIVE_FILTER_NAMES']
    pipeline_name = ENV['INTAKE_PIPEDRIVE_PIPELINE_NAME']

    pipeline = get_pipeline(pipeline_name)
    pipeline_id = pipeline['id']
    pipeline_deals = get_pipeline_deals(pipeline_id)
    pipeline_deals_filtered = filter_pipeline_deals(pipeline_deals, filter_names)
    pipeline_stages = pipeline_stages(pipeline_id)

    # aggregate
    export(pipeline_stages, 'Substantial', filter_names.split(',')[0], pipeline_deals, pipeline_deals_filtered)
  end

  def export(stages, unfiltered_name, filtered_name, unfiltered_deals, filtered_deals)
    pipeline_summary = []

    if stages.nil? || stages.empty? || unfiltered_deals.nil? || unfiltered_deals.empty?
      return pipeline_summary
    end

    stages.sort! { |x,y| x['order_nr'] <=> y['order_nr'] }

    stages.each do |stage|
      filtered_deals_summarized = summarize_deals(filtered_name, stage, filtered_deals.reject{ |deal| deal['stage_id'] != stage['id'] })
      unfiltered_deals_summarized = summarize_deals(unfiltered_name, stage, unfiltered_deals.reject{ |deal| deal['stage_id'] != stage['id'] })

      stage_summary = {
          name: stage['name'],
          datasets: [filtered_deals_summarized, unfiltered_deals_summarized]
      }

      pipeline_summary << stage_summary
    end

    Rails.logger.debug("Final output: #{pipeline_summary.inspect}")
    pipeline_summary
  end

  def summarize_deals(name, stage, deals)
    deals_value = 0
    stage_id = stage['id']
    deals.each do |deal|
      if deal['stage_id'] == stage_id
        deals_value += deal['value']
      end
    end

    {
      name: name,
      dollar_value: deals_value,
      deal_count: deals.size
    }
  end

  def get_pipeline(name)
    # find the pipeline
    pipelines_uri_component = 'pipelines'
    pipelines = data_from_uri(pipelines_uri_component)

    unless pipelines.nil?
      pipelines.detect do |item|
        item['name'] == name
      end
    end
  end

  def get_pipeline_deals(pipeline_id)
    deals_uri_component = "pipelines/#{pipeline_id}/deals"
    pipeline_deals = data_from_uri(deals_uri_component)

    if pipeline_deals.nil?
      pipeline_deals = []
    end

    pipeline_deals.delete_if { |deal| deal['status'] != 'open' }
  end

  def filter_pipeline_deals(deals, filter_names)
    if filter_names.nil? || filter_names.empty? || deals.nil? || deals.empty?
      return deals
    end

    # get filters using the filter names
    # TODO: make this work for more than one filter name
    filter_name = filter_names.split(',')[0]
    if filter_name.nil? || filter_name.empty?
      return deals
    end

    # PipeDrive API doesn't allow direct selection of filters by name, so must get all and select manually
    filters_uri_component = 'filters'
    all_filters = data_from_uri(filters_uri_component)

    if all_filters.nil? || all_filters.empty?
      return deals
    end

    filtered_deals = []
    all_filters.each do |filter_metadata|
      if filter_metadata['name'] == filter_name
        # now get this specific filter from the API
        filter_uri_component = "filters/#{filter_metadata['id']}"
        filter = data_from_uri(filter_uri_component)

        # get persons listed in the filter
        person_filter_conditions = find_conditions_by_object_type(filter, 'person')

        # now we can get deals for each person!
        unless person_filter_conditions.nil?
          person_filter_conditions.each do |person_filter_condition|
            deals.each do |deal|
              if deal['user_id'].to_s == person_filter_condition['value'] && deal['status'] == 'open'
                filtered_deals << deal
              end
            end
          end
        end
      end
    end

    filtered_deals
  end

  def pipeline_stages(pipeline_id)
    all_stages = data_from_uri('stages')
    if all_stages && all_stages.is_a?(Array)
      all_stages.select { |stage| stage['pipeline_id'] == pipeline_id && stage['active_flag'] }
    end
  end

  def find_conditions_by_object_type(enumerable, object_name)
    droids_you_are_looking_for = []
    if enumerable.nil? || object_name.nil?
      return droids_you_are_looking_for
    end

    enumerable.each do |obj|
      v = obj.kind_of?(Array) ? obj.last : obj
      case v
        when Array then
          droids_you_are_looking_for.concat(find_conditions_by_object_type(v, object_name))
        when Hash then
          v.each_pair do |k,vv|
            if k.to_s == 'conditions'
              droids_you_are_looking_for.concat(find_conditions_by_object_type(vv, object_name))
            elsif k.to_s == 'object' && vv.to_s == object_name
              droids_you_are_looking_for << v
              break
            end
          end
        else
          # do nothing
      end
    end

    droids_you_are_looking_for
  end

  def data_from_uri(uri_suffix)
    api_url = ENV['INTAKE_PIPEDRIVE_API_URL']
    token = ENV['INTAKE_PIPEDRIVE_API_TOKEN']

    if api_url.nil?
      Rails.logger.error "Environment variable 'INTAKE_PIPEDRIVE_API_URL' is not specified"
    end
    if token.nil?
      Rails.logger.error "Environment variable 'INTAKE_PIPEDRIVE_API_TOKEN' is not specified"
    end

    api_url = "#{api_url}/" unless api_url.end_with? '/'

    uri = URI.join(api_url, "#{uri_suffix}?api_token=#{token}")

    is_ssl = uri.scheme == 'https'
    req = Net::HTTP::Get.new(uri)
    req['Accept'] = 'application/json'

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: is_ssl) do |http|
      http.request(req)
    end

    unless Net::HTTPSuccess===res
      Rails.logger.error "#{self.class} received an unsuccessful response: #{res.inspect}"
      return
    end

    json = JSON.parse(res.body)
    unless json['success']
      Rails.logger.error "Pipedrive API returned success=false for uri: #{uri.inspect} Response: #{res.inspect}"
      return
    end

    json['data']
  end
end
