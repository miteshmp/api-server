class ServiceMonitoringController < ApplicationController
	include ServiceMonitoringHelper
	
	def index
		@service_statuses = get_service_data()
	end

	
end