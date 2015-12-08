class Recurly2API_v1 < Grape::API
	version 'v1', :using => :path,  :format => :xml
  	format :xml
  	formatter :json, SuccessFormatter  	 

	resource :recurly do

        desc "Recurly push notification"
        post 'recurly_push_notification' do

          case params.keys[0]
          when "new_account_notification"           # Account is created after device register . plan_id is set after getting subscription notification
            account_code = params["new_account_notification"]["account"]["account_code"]
          
          when "canceled_account_notification"      # Account is cancelled when the device is deleted. Should consider device soft delete
            account_code = params["canceled_account_notification"]["account"]["account_code"]
          
          when "billing_info_updated_notification"  # Not applicable
            account_code = params["billing_info_updated_notification"]["account"]["account_code"]
         
          when "reactivated_account_notification"   # Not applicable
            account_code = params["reactivated_account_notification"]["account"]["account_code"]

          when "new_subscription_notification"      # This is already handled in confirm
            account_code = params["new_subscription_notification"]["account"]["account_code"]
            
            device = Device.where(registration_id: account_code).first

            if device  
              device.plan_id = params["new_subscription_notification"]["subscription"]["plan"]["plan_code"]
              device.plan_changed_at = params["new_subscription_notification"]["subscription"]["activated_at"]
              device.save!
              device.send_plan_id
            else
              Notifier.recurly_exception(params,"There is a discrepancy. Device registration id is not found. However recurly has created an account for this device.").deliver
            end  
          
          when "updated_subscription_notification"   # on upgrade or downgrade of subscription . Have to check if customer was previously on "High relay usage list"
            account_code = params["updated_subscription_notification"]["account"]["account_code"]
            
            device = Device.where(registration_id: account_code).first
            if device  
              device.plan_id = params["updated_subscription_notification"]["subscription"]["plan"]["plan_code"]
              device.plan_changed_at = params["updated_subscription_notification"]["subscription"]["activated_at"]
              
              #device.relay_usage_reset_date = nil # SET IF PLAN 
              #device.high_relay_usage = false     # IS UPGRADED

                device.upnp_usage = 0
                device.stun_usage = 0
                device.relay_usage = 0
                device.upnp_count = 0
                device.stun_count = 0
                device.relay_count = 0
                device.high_relay_usage = 0
                device.relay_usage_reset_date = nil
                device.latest_relay_usage = 0
                device.high_relay_usage = false

              
              device.save!
              device.send_plan_id
            end  

          when "canceled_subscription_notification"   # set plan_id to inactive
            account_code = params["canceled_subscription_notification"]["account"]["account_code"]
            device = Device.where(registration_id: account_code).first

            if device
              device.plan_id = "inactive"
              device.plan_changed_at = params["canceled_subscription_notification"]["subscription"]["activated_at"]
              
              device.save!
              device.send_plan_id
            end  
          
          when "expired_subscription_notification"   # If you receive this message, the account no longer has a subscription
            account_code = params["expired_subscription_notification"]["account"]["account_code"]
            device = Device.where(registration_id: account_code).first

            if device
              device.plan_id = "inactive"
              device.plan_changed_at = params["expired_subscription_notification"]["subscription"]["activated_at"]
              
              device.save!
              device.send_plan_id
            end 

          when "renewed_subscription_notification"    # what should be done !!!!  
            account_code = params["renewed_subscription_notification"]["account"]["account_code"]  
          
          when "successful_payment_notification"     # Gives transaction id,invoice id,invoice number, subscription_id. Should we store these details
            account_code = params["successful_payment_notification"]["account"]["account_code"] 

          when "failed_payment_notification"         # what should be done !!!!   
            account_code = params["failed_payment_notification"]["account"]["account_code"] 

          when "successful_refund_notification"      # Not applicable
            account_code = params["successful_refund_notification"]["account"]["account_code"] 
            
          when "void_payment_notification"
            account_code = params["void_payment_notification"]["account"]["account_code"] 
            
          else
            account_code ="unknown"
          end                
               
        end  

        

	end	
end	