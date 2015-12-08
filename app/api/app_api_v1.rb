require 'json'
require 'grape'
require 'error_format_helpers'

class AppAPI_v1 < Grape::API
  formatter :json, SuccessFormatter
  format :json
  default_format :json
  version 'v1', :using => :path, :format => :json

  helpers AwsHelper

  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :apps do

    desc "List of all apps that belong to current user. "
    get  do
      authenticated_user
      status 200
      present current_user.apps, with: App::Entity
    end

    desc "Create an app that belongs to current user. "
    params do
    requires :name, :type => String, :desc => "Name of the app"
    requires :device_code, :type => String, :desc => "Device code"
    requires :software_version, :type => String, :desc => "Software version"
    

  end
    post 'register' do
      authenticated_user

      app = current_user.apps.where(device_code: params[:device_code]).first

      unless app
        app = current_user.apps.new
        app.device_code = params[:device_code]
        app.name = params[:name]
        app.software_version = params[:software_version]

        app.save!
      end  

      status 200
      present app, with: App::Entity
    end

    desc "Register device for push notification. "
    params do
      requires :notification_type, :validate_notification_type => true, :desc => "Notification type. Currently supports 'gcm' and 'apns'"
      requires :registration_id, :type => String, :desc => "App registration id or device token provided by either GCM or APNS."
    end
    post ':id/register_notifications' do
      authenticated_user

      app = current_user.apps.where(id: params[:id]).first
      not_found!(APP_DOES_NOT_BELONG_TO_USER, "App: " + params[:id].to_s) unless app

        app.notification_type = params[:notification_type]
        app.registration_id = params[:registration_id]
        app.sns_endpoint = register_for_mobile_push(params[:notification_type], params[:registration_id])
        app.save!
            
        status 200
        present app, with: App::Entity
    end

    desc "Unregister push notification device. "
    post ':id/unregister_notifications' do
      authenticated_user
      app = current_user.apps.where(id: params[:id]).first
      not_found!(APP_DOES_NOT_BELONG_TO_USER, "App: " + params[:id].to_s) unless app

      app.registration_id = nil
       app.notification_type = "none"
      app.save!
      
      status 200
      present app, with: App::Entity
    end

    desc "Update app."
    params do
      optional :name, :type => String, :desc => "Name of the app"
      requires :software_version, :type => String, :desc => "Software version"
    end
    put ':id' do
      authenticated_user
      app = current_user.apps.where(id: params[:id]).first
      not_found!(APP_DOES_NOT_BELONG_TO_USER, "App: " + params[:id].to_s) unless app

      app.name = params[:name] if params[:name]
      app.software_version = params[:software_version]
      app.save!

      status 200
      present app, with: App::Entity
    end


    desc "Unregister/delete an app from the server. This will delete the app record completely, including the corresponding notification settings for the app."
    delete ':id/unregister' do
      authenticated_user
      app = current_user.apps.where(id: params[:id]).first
      not_found!(APP_DOES_NOT_BELONG_TO_USER, "App: " + params[:id].to_s) unless app

      App.destroy(app.id)
     
      status 200
      "App Deleted!"
    end

    desc "Update device alert settings. ", {
        :notes => <<-NOTE
    The parameter settings takes an array. An example of the input is shown as follows:
    {
      "api_key" : "some_api_key......",
      "settings" : [ 
        { "device_id" : 1, "alert" : 1, "is_enabled" : false },
        { "device_id" : 1, "alert" : 2, "is_enabled" : false },
        { "device_id" : 2, "alert" : 2, "is_enabled" : false },
        { "device_id" : 2, "alert" : 1, "is_enabled" : true }
  ]
}

*** This query CANNOT be executed using Swagger framework. Please use some REST client (like Postman, or RESTClient etc.)
    NOTE
      }
    params do
      requires :settings, :type => Array, :desc => "App notification settings. This takes a JSON array. See query notes for example."
    end
    put ':id/notification_settings' do
      authenticated_user

      app = current_user.apps.where(id: params[:id]).first
      not_found!(APP_DOES_NOT_BELONG_TO_USER, "App: " + params[:id].to_s) unless app

      params[:settings].each do |item|
        device_id = ""
        alert = ""
        is_enabled = ""
        begin
        	device_id = item.device_id
        	alert = item.alert
        	is_enabled = item.is_enabled

        rescue Exception => NoMethodError
          bad_request!(INVALID_APP_SETTINGS_FORMAT,"Parameter 'settings' should be a JSON array .")
      end 
        device = current_user.devices.where(id: item.device_id).first
        not_found!(DEVICE_DOES_NOT_BELONG_TO_USER, "Device: " + device_id.to_s) unless device
        
        obj = app.device_app_notification_settings.where(device_id: device_id, alert: alert).first

        unless obj          
          obj = app.device_app_notification_settings.new 
          obj.device_id = device_id
          obj.alert = alert
        end        
        obj.is_enabled = is_enabled  

        obj.save!                
      end
      
      status 200
      "Done"
      
    end
  end
  
end