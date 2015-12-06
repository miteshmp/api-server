class ExternalNotifier
# Class that pushes to external services

	attr_accessor :provider

	def initialize(data)
		@provider = get_the_provider(data)
	end

	# User register
	def user_register(data)
		@provider.user_register(data) if @provider
	end	

	# User update
	def user_update(data)
		@provider.user_update(data) if @provider
	end	

	# User delete
	def user_delete(data)
		@provider.user_delete(data) if @provider
	end

	# Device register
	def device_register(data)
		@provider.device_register(data) if @provider
	end	

	# Device update
	def device_update(data)
		@provider.device_update(data) if @provider
	end	

	# Device delete
	def device_delete(data)
		@provider.device_delete(data) if @provider
	end

	# Push notification
	def send_push_notification(data)
		@provider.send_push_notification(data) if @provider
	end

	# Return the provider name
	def get_the_provider(data)

		model = data[:device].registration_id[2..5]

		if GeneralSettings.alcatel_config.models.include? model
			return HubbleHttp::AlcatelProvider.new
		end	
	end	


end	