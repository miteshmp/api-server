module ServiceMonitoringHelper

  def get_service_data()
    response = nil
    service_statuses = Array.new
    begin
      response = HTTParty.post(Settings.newrelic_applications_url,:headers => { 'Content-Type' => 'application/json', 'X-Api-Key' => Settings.newrelic_api_key })
      if response.code == 200
        data = JSON.parse(response.body)
        data["applications"].each do |app|
          status = {'name' => map_application_names_to_friendly_names(app["name"]), 'status' => app["health_status"]}
          service_statuses.push(status)
        end
      end
    rescue Errno::ENETUNREACH
      service_statuses.push({'name' => 'All services', 'status' => 'Information not available'})
    rescue SocketError => e
      service_statuses.push({'name' => 'All services', 'status' => 'Information not available'})
    end
    service_statuses
  end

  def map_application_names_to_friendly_names( new_relic_name )
    case new_relic_name
    when 'Portal Agent'
      return t('monitoring.portal_agent')
    when 'Production API Server'
      return t('monitoring.api')
    when 'Talkback Server'
      return t('monitoring.talkback')
    when 'Upload Server'
      return t('monitoring.upload')
    else
      return new_relic_name
    end
  end
end
