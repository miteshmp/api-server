class RegistrationDetail < ActiveRecord::Base
	include Grape::Entity::DSL
  	extend Enumerize

  	attr_accessible :registration_id,:mac_address,:local_ip,:remote_ip,:net_mask,:gateway,:expire_at

    attr_accessor :device_status
    
  	entity :id,
  		:local_ip,
  		:net_mask,
  		:gateway do
    		expose :device_status, if: { type: :full }
    end


    validates :registration_id, :allow_nil => false, uniqueness: { case_sensitive: false }
  	validates :mac_address, :allow_nil => false, uniqueness: { case_sensitive: false }

  	# Method :- get_registration_detail_expire_time
  	# Description :- it should provide registration detail expire time
  	def get_registration_detail_expire_time

    	expire_time = Time.now.utc.to_i + HubbleConfiguration::REGISTRATION_DETAILS_EXPIRE_TIME_SECONDS ;
    	return expire_time.to_s; 

  	end


  	# Method :- validate_registration_detail_expire_time
  	# Description :- Validate that Registration details expire or not

  	def validate_registration_detail_expire_time

    	# check that registration details expire or not
    	if ( self.expire_at &&  ( self.expire_at.to_i > Time.now.utc.to_i) )
      		return true; 
    	end

    	return false;
  	end
  	

end