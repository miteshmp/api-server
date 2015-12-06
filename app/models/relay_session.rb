class RelaySession < ActiveRecord::Base
	include Grape::Entity::DSL
  	attr_accessible :registration_id, :session_key, :stream_id

  	validates :registration_id, :allow_nil => false, uniqueness: { case_sensitive: false }
  	 
  	 entity :registration_id,
	  :session_key,
	  :stream_id do
	  end

  	# generate session key of 64 byte
	def generate_session_key
		session_key = loop do
		  random_token = SecureRandom.urlsafe_base64(24).to_hex_string.delete(' ').upcase
		  break random_token unless RelaySession.exists?(session_key: random_token)
		end
	end

	# generate stream id of 12 byte
	def generate_stream_id 
		stream_id  = loop do
		  random_token = SecureRandom.urlsafe_base64(4.5).to_hex_string.delete(' ').upcase
		  break random_token unless RelaySession.exists?(stream_id: random_token)
		end
	end

	# convert ip to hex
	def convert_ip(ip)
    ip_reverse = ip.to_s.split('.').reverse.join('.')
    ip_hex = IP.new(ip_reverse).to_hex.upcase
  end
end
