class MandrillWrapper
	include Singleton
	attr_accessor :mandrill

	def initialize
		@mandrill = Mandrill::API.new Settings.mandrill_api_key
	end	
end	
