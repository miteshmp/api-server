require 'grape'
require 'json'
class DeviceSettingsAPI_v1 < Grape::API

  include Audited::Adapters::ActiveRecord
  
   

  formatter :json, SuccessFormatter
  format :json
  default_format :json
  content_type :json, "application/json"
  version 'v1', :using => :path, :format => :json

  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  helpers DeviceCommandHelper

  resource :device_settings do
 
    # Query :- Set the extended attribute.
    # Method :- POST
    # Parameters :-
    #         registration_id:-  registration_id
    #         key :-  Key 
    #         value :- Key value
    # Response :-
    #         Return extended attribute message 
    #
   desc "Set the device settings."

   params do
   	 requires :entity_code, :type => String, :desc => "entity_code may be user id or device registration_id"
     requires :key, :type => String, :desc => "Key should not not contain comma."
     requires :value, :type => String, :desc => "Value."
     requires :entity_type, :type => String, :desc => "entity_type should be Device Or User"

  end

      post  do
		
        
        invalid_parameter!("key") if ExtendedAttribute.invalid_key(params[:key]) ;

        active_user = authenticated_user ;

        if params[:entity_type].capitalize == "Device"
          entity = Device.where(registration_id: params[:entity_code]).first

          not_found!(DEVICE_NOT_FOUND, "Device: " + params[:entity_code].to_s) unless entity
          forbidden_request! unless active_user.has_authorization_to?(:update, entity)

        elsif  params[:entity_type].capitalize == "User"

          entity = User.where(id: params[:entity_code]).first

          not_found!(USER_NOT_FOUND, "User: " + params[:entity_code].to_s) unless entity
          forbidden_request! unless active_user.has_authorization_to?(:update, entity)

        else  
          invalid_parameter!("entity_type") 
        end


        extended_attribute = ExtendedAttribute.where(entity_id: entity.id,entity_type: params[:entity_type],key: params[:key]).first

        extended_attribute = ExtendedAttribute.new unless extended_attribute
        extended_attribute.entity_id=entity.id
        extended_attribute.entity_type=params[:entity_type].capitalize
        extended_attribute.device_attribute_set_by_user(params[:key],params[:value]) ;

        send_command(CMD_SET_REC_DESTINATION,entity,nil,params[:value])
        
        present extended_attribute, with: ExtendedAttribute::Entity

      #post end  
      end

 	  # Complete Query :- "extended attribute"
 	  # Query :- List of all extended attributes.
    # Method :- GET
    # Parameters :-
    #         key :-  Key 
    #         value :- Key value
    # Response :-
    #         Return extended attribute message
    # 

    desc "List of all device settings"
    
     params do
      requires :entity_code, :type => String, :desc => "entity_code may be user id or device registration_id"
      end
      
       get  do

        active_user = authenticated_user ;
        device = Device.where(registration_id: params[:entity_code]).first
        not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
       # forbidden_request! unless active_user.has_authorization_to?(:read_any, device)
         
        status 200 
    
       present device.extended_attributes, with: ExtendedAttribute::Entity
      end
      
#resource end      
end
end