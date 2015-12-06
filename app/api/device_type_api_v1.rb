require 'grape'
require 'json'

class DeviceTypeAPI_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
	format :json
	 version 'v1', :using => :path, :format => :json
   formatter :json, SuccessFormatter

   helpers AwsHelper

   params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end


resource :device_types do
  desc "Register a new Device type"
    params do
      requires :name, :type => String, :desc => "Specific Device type"
      requires :type_code, :type => String, :desc => "Device type code"
      requires :description , :type =>String, :desc => "Type Description"
    end 

post 'register' do 
authenticated_user

forbidden_request! unless current_user.has_authorization_to?(:create, DeviceType)

device_type = DeviceType.new
device_type.name = params[:name]
device_type.type_code = params[:type_code]
device_type.description = params[:description]
Audit.as_user(current_user) do 
  device_type.save!
end  
status 200
present device_type, with: DeviceType::Entity
end



desc "Get the list of device type"
params do
      optional :q, :type => Hash, :desc => "Search parameter"
      optional :page, :type => Integer
      optional :size, :type => Integer
    end
  get   do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceType)

      status 200
      search_result = DeviceType.search(params[:q])
      device_types = params[:q] ? search_result.result(distinct: true) : DeviceType
      
      present device_types.paginate(:page => params[:page], :per_page => params[:size])  , with: DeviceType::Entity
      
  end

    

desc "Get a specific device type"
    get ':type_code'  do
      authenticated_user

      device_type = DeviceType.where(type_code: params[:type_code]).first
      not_found!(USER_NOT_FOUND, "DeviceType: " + params[:type_code].to_s) unless device_type

      forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceType)

      status 200
      present device_type, with: DeviceType::Entity
    end



desc "Delete a device type"
params do
  requires :comment, :type => String, :desc => "Comment"
end  
 delete  ':type_code'  do
      authenticated_user

      device_type = DeviceType.where(type_code: params[:type_code]).first
      not_found!(TYPE_NOT_FOUND, "DeviceType: " + params[:type_code].to_s) unless device_type

      forbidden_request! unless current_user.has_authorization_to?(:destroy, device_type)
      invalid_request!(DEVICE_TYPE_IN_USE, "Device type has device models associated with it. Delete all device models before deleting this device type.") unless device_type.device_models.empty?

      device_type.audit_comment = params[:comment]
      
      Audit.as_user(current_user) do 
        device_type.destroy
      end  

      status 200
      "Type deleted!" 
  end

desc "update a device type"
 params do
      requires :name, :type => String, :desc => "Specific device type"
      requires :description , :type =>String
    end  

put ':type_code' do 
  authenticated_user

  device_type = DeviceType.where(type_code: params[:type_code]).first
  not_found!(TYPE_NOT_FOUND, "DeviceType: " + params[:type_code].to_s) unless device_type

  forbidden_request! unless current_user.has_authorization_to?(:update, device_type)

  device_type.name = params[:name]
  device_type.description = params[:description]

  Audit.as_user(current_user) do 
    device_type.save!
  end  

  status 200
  present device_type
end

# desc "Set capabilty for specific device type", {
#     :notes => <<-NOTE
#     The parameter capability takes an array. An example of the input is shown as follows:
#   {
#     "capability" : [ 
#     { "parameter" : "zoom", "type" : "range" ,"control" : true},
#     { "parameter" : "pan", "type" : "range" ,"control" : true}
#         ] }

#    * Value of type should be either of range, list, number or string within double quotes.
#    * Value of parameter should be within double quotes.
#    * Value of control should be either true or false within double quotes. 
#    * control = false indicates for information purpose only and control = true indicates that the value can be changed.
    
#     *** This query CANNOT be executed using Swagger framework. Please use some REST client (like Postman, or RESTClient etc.)
#     NOTE
#   }
# params do
# requires :capability, :type => Array, :desc => "Device type capability. This takes a JSON array. See query notes for example."
#  end 
#  put ':type_code/set_capability' do
#   authenticated_user

#   device_type = DeviceType.where(type_code: params[:type_code]).first
#   not_found!(TYPE_NOT_FOUND, "DeviceType: " + params[:type_code].to_s) unless device_type
  
#   forbidden_request! unless current_user.has_authorization_to?(:update, device_type)
#   params[:capability].each do |capability|
   
#      bad_request!(INVALID_CAPABILITY_FORMAT,"Parameter capability does not contain necessary fields.") unless (capability.respond_to?("parameter") && capability.respond_to?("type") && capability.respond_to?("control"))
#      bad_request!(INVALID_CAPABILITY_FORMAT,"parameter should not be null.") if capability.parameter.is_empty?
#      bad_request!(INVALID_CAPABILITY_FORMAT,"Type should be either of range, list, number or string.") unless capability.type.in?(["range","list","number","string"])
#      bad_request!(INVALID_CAPABILITY_FORMAT,"Control should be either true or false within double quotes.") unless capability.control.in?(["true","false"])
#   end

#   device_type.capability = params[:capability]
#   Audit.as_user(current_user) do 
#     device_type.save!
#   end  

#   present device_type, with: DeviceType::Entity


#  end

   desc "Get audits related to a specific device_type "
    get ':type_code/audit'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceType)

       device_type = DeviceType.with_deleted.where(type_code: params[:type_code]).first
       not_found!(TYPE_NOT_FOUND, "DeviceType: " + params[:type_code].to_s) unless device_type
       status 200
      {
        "device_type_audits" => device_type.audits,
       "device_type_associated_audits" => device_type.associated_audits
     }
    end

  
    desc 'Set device_type capability by uploading csv file'
    params do 
        requires :type_code
        requires :file, :desc => "Device type capability csv file."
    end 
    post 'device_type_capability' do 
        authenticated_user

        device_type = DeviceType.where(type_code: params[:type_code]).first
        not_found!(TYPE_NOT_FOUND, "DeviceType: " + params[:type_code].to_s) unless device_type
        forbidden_request! unless current_user.has_authorization_to?(:update, device_type)

        bad_request!(INVALID_FILE, "Invalid file") unless params[:file].respond_to?("filename")         
        name =  params[:file].filename
        directory = Settings.capabiltity_directory
        FileUtils.mkdir_p directory unless File.exist?(directory)

       
        # create the file path
        path = File.join(directory, name)   

        begin
            File.open(path, "w+") { |f| f.write(params[:file].tempfile.read) }

            results = import(path) do
                start_at_row 1
                [
                     param,
                     type,
                     control
                ]
            end
         rescue
            FileUtils.rm_rf(path)  
            bad_request!(INVALID_FILE, "Invalid file. Please upload only csv files.")  
         end   
         
        capabilities = []
        error_messages = []
        i = 1

     results.each do |capability|
        i = i +1
        FileUtils.rm_rf(path)
        
          error_messages << {:line => i, :param => capability.param, :error => "Parameter should not be null."} if (!capability.param || capability.param.is_empty?)
          error_messages << {:line => i, :param => capability.param, :error => "Parameter is not having valid format."} unless  (!capability.param || capability.param.match(/^[a-zA-Z0-9_]+$/))
          error_messages << {:line => i, :param => capability.param, :error => "Type should be either of range, list, number, bool or string."} unless (!capability.param || capability.type.in?(["range","list","number","string","bool"]))
          error_messages << {:line => i, :param => capability.param, :error => "Control should be either true or false within double quotes."} unless (!capability.param || capability.control.in?(["true","false"]))
        capabilities << JSON.parse(capability.to_json)
  end
     

     parameters = []
     capabilities.each do |hash|  # Checking if there are duplicate parameters
        parameters << hash["param"]
     end   
     error_messages << {:line => 0, :param => "NA", :error => "Device type capability provided has duplicate parameters."} unless parameters.length == parameters.uniq.length      
      bad_request!(INVALID_CAPABILITY_FORMAT,error_messages) if error_messages.count>0
      device_type.capability = capabilities
      
      Audit.as_user(current_user) do 
        device_type.save!
      end  
      status 200
      upload_type_capability_to_s3(params[:file],params[:type_code])
      present device_type, with: DeviceType::Entity

    end


end 
end
