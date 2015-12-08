class RecurlyAPI_v1 < Grape::API
	version 'v1', :using => :path,  :format => :json
  	format :json
  	formatter :json, SuccessFormatter  	 

	helpers RecurlyHelper

	resource :recurly do


      desc "Recurly subscription confirm" 
      params do
        requires :recurly_token, :type => String, :desc => "Token returned from recurly after subscription"
      end  
       
      post 'confirm_subscription' do
        # begin
        #   result = Recurly.js.fetch params[:recurly_token]
           
        #   unless result.respond_to?("uuid") 
        #     Notifier.recurly_subscription(params[:recurly_token]).deliver
        #   else  
        #      uuid  = result.uuid
        #      subscription_details = list_subscription_details(uuid)
            
        #      device = Device.where(registration_id: subscription_details.account.account_code).first
        #      unless device 
        #         Notifier.recurly_subscription(params[:recurly_token]).deliver 
        #      else
        #        device.plan_id = subscription_details.plan.plan_code
        #        device.plan_changed_at = subscription_details.activated_at
        #        device.save!
        #        device.send_plan_id
        #        status 200
        #        "Confirmed subscription"
        #     end   
        #   end
        # rescue Exception => e
        #     Notifier.recurly_exception(params[:recurly_token],e.message).deliver

        # end       
          
         
      end

       
        

	end	
end	