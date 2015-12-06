require 'json'
require 'grape'
require 'error_format_helpers'

class Background_Tasks_api_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
  formatter :json, SuccessFormatter
  format :json
  default_format :json
  version 'v1', :using => :path, :format => :json

  helpers AwsHelper

  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :background_tasks do

    desc "Get registration_ids based on specific subscription_type " 
     params do
      requires :plan_id, :type => String, :desc => "Either of inactive,freemium, tier1, tier2 or tier3"
     end 
     get 'get_ids' do
        authenticated_user
        status 200

        forbidden_request! unless current_user.has_authorization_to?(:read_any, Device)
        if params[:plan_id] =="inactive"
          devices = Device.where('plan_id =? AND plan_changed_at <=?',"inactive",Time.now - Settings.hours_stored.to_i.hours).map(&:registration_id) 
        else  
          devices = Device.where(plan_id: params[:plan_id]).map(&:registration_id)
        end  
          devices
     end 

      desc "Deactivation process for freemium users. This query finds all devices which are not accessed recently and sets a target_deactivate_date. Also sends a notification to the users." 
     post 'deactivation_check' do
        authenticated_user
        status 200

        forbidden_request! unless current_user.has_authorization_to?(:deactivate, Device)
        # Get freemium devices registration_ids which are not accessed for long
        inactive_devices = Device.where("plan_id = ? AND last_accessed_date <= ? AND target_deactivate_date is ?","freemium",Time.now - Settings.hours_inactive.to_i.hours,nil)
        
        #send notification that device will be deactivated after 3 days 
        inactive_devices.each do |device|
          user = User.where(id: device.user_id).first
          send_batch_notification(user,device,"deactivate") if user
        end  

        # Set target_deactivate_date
        inactive_devices.each do |device|
            device.target_deactivate_date = Time.now+Settings.deactivate_after.to_i.hours 
            Audit.as_user(current_user) do   
              device.save! 
            end   
        end  

     end 

     desc "Deactivate the freemium devices. Finds devices whose target deactivation date has elapsed and sets subscription plan to inactive if device is not accessed recently."
     
     post 'deactivate' do
        authenticated_user
        status 200
        forbidden_request! unless current_user.has_authorization_to?(:deactivate, Device)
        devices = Device.find(:all, :conditions => ["target_deactivate_date <= ?", Time.now])
        devices.each do |device|
           if Time.now-device.last_accessed_date>=Settings.deactivate_after.to_i.hours
              device.plan_id = "inactive"

              account = Recurly::Account.find(device.registration_id)    # Cancelling the recurly account as device has become inactive
              account.destroy if account 
           end
          device.target_deactivate_date = nil
          device.deactivate = false
          device.send_plan_id
          Audit.as_user(current_user) do  
            device.save!
          end  
        end
     end 

     desc "Check for high relay usage." 
     post 'check_high_relay_usage' do
        authenticated_user
        status 200

        forbidden_request! unless current_user.has_authorization_to?(:check_high_usage, Device)
        devices = Device.all
        devices.each do |device| 
          sum = device.relay_usage
          count = device.relay_count
          if count >0
            avg = sum/count
            val = ((sum * ((device.latest_relay_usage - avg) ** 2)) / count) * 2
            threshold = avg + Math.sqrt(val) # threshold = avg+sqrt(((sum(x-avg)^2)/count))*2

            if sum > threshold
              user = User.where(id: device.user_id).first
              send_batch_notification(user,device,"upgrade")  if user# Send Push notification prompting user to upgrade
              device.high_relay_usage = true
              device.relay_usage_reset_date = Time.now+Settings.wait_for.to_i.hours 
              Audit.as_user(current_user) do   
                device.save!
              end  
           end 
          end 
       end  
     end 

     desc "Video quality Downgrade for overly active relay users." 
     post 'downgrade_streaming_video_quality' do
        authenticated_user
        status 200

        forbidden_request! unless current_user.has_authorization_to?(:check_high_usage, Device)
        devices = Device.where('plan_id = ? AND relay_usage_reset_date <= ?',"freemium", Time.now)
        devices.each do |device|
           device.send_downgrade_streaming_video_quality_command if device.plan_id == "freemium" # Store to camera: Downgrade streaming video quality to 2FPS if subscription_plan is freemium
           device.relay_usage_reset_date = nil
           Audit.as_user(current_user) do   
            device.save!
          end  
        end
     end

     desc "Delete s3 events based on the subcription plan of each device" 
     post 'delete_s3_events' do
      authenticated_user
      status 200

      forbidden_request! unless current_user.has_authorization_to?(:delete_s3_events, Device)
      plans = Device.all.map(&:plan_id).uniq
      registration_ids = []
      plans.each do |plan|
        if plan =="inactive"
          devices = Device.includes(:device_events).select('id,registration_id,mode').where('plan_id =? AND plan_changed_at <=?',"inactive",Time.now - Settings.hours_stored.to_i.hours)
        else  
          devices = Device.includes(:device_events).select('id,registration_id,mode').where(plan_id: plan)
        end
        
        limit = get_limit(plan) 
        delete_objects(devices,limit)
      end  

     end



  end
end