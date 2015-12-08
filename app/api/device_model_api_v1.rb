require 'grape'
require 'json'


class DeviceModelAPI_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
	format :json
  version 'v1', :using => :path, :format => :json
  formatter :json, SuccessFormatter

  helpers AwsHelper

  before do
    User.stamper = current_user
  end  

  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end


  resource :device_models do
    desc "Register a new model "
    params do
      requires :type_code, :type => String, :desc => "Type code"
      requires :name, :type => String, :desc => "Specific model name"
      requires :model_no, :type => String, :desc => "Model code"
      requires :udid_scheme, :type => Integer, :desc => "UDID scheme. 1 for Monitor Device Type and 2 for Desktop device type"
      requires :description , :type =>String, :desc =>"Model description"
    end 
    

    post 'register' do 
      authenticated_user
      
      device_type = DeviceType.where(type_code: params[:type_code]).first
      not_found!(TYPE_NOT_FOUND, "DeviceType: " + params[:type_code].to_s) unless device_type

      forbidden_request! unless current_user.has_authorization_to?(:create, DeviceModel)

      model = device_type.device_models.new
      model.name = params[:name]
      model.model_no = params[:model_no]
      model.udid_scheme = params[:udid_scheme]
      model.description = params[:description]
      Audit.as_user(current_user) do 
        model.save!
      end  
      status 200
      present model, with: DeviceModel::Entity
    end

    desc "get the list of models"
     params do
      optional :q, :type => Hash, :desc => "Search parameter"
      optional :page, :type => Integer
      optional :size, :type => Integer
    end
    get do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceModel)

      status 200

      search_result = DeviceModel.search(params[:q])
      device_models = params[:q] ? search_result.result(distinct: true) : DeviceModel
      
      present device_models.paginate(:page => params[:page], :per_page => params[:size])  , with: DeviceModel::Entity
    end

    

    desc "Get a specific device model"
    get ':model_no'  do
      authenticated_user

      device_model = DeviceModel.where(model_no: params[:model_no]).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

      forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceModel)
      status 200
      present device_model, with: DeviceModel::Entity
    end



    desc "Delete an model"
    params do
      requires :comment, :type => String, :desc => "Comment"
    end 
    delete  ':model_no'  do
      authenticated_user

      device_model = DeviceModel.where(model_no: params[:model_no]).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

      forbidden_request! unless current_user.has_authorization_to?(:destroy, device_model)

     
      invalid_request!(DEVICE_MODEL_IN_USE, "Device model has devices associated with it. Delete all devices before deleting this device model.") unless device_model.devices.empty?
      device_model.audit_comment = params[:comment]
      
      Audit.as_user(current_user) do 
        device_model.destroy
      end  

      status 200
      "Model deleted!" 
    end


    desc "update an model"
    params do
      requires :name, :type => String, :desc => "Specific device name"
      requires :description , :type =>String
      optional :udid_scheme, :type => Integer, :desc => "UDID scheme. 1 for Monitor Device Type and 2 for Desktop device type"
    end 


    put ':model_no' do 
      authenticated_user

      device_model = DeviceModel.where(model_no: params[:model_no]).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

      forbidden_request! unless current_user.has_authorization_to?(:update, device_model)

      device_model.name = params[:name]
      device_model.model_no = params[:model_no]
      device_model.udid_scheme = params[:udid_scheme] if params[:udid_scheme]
      device_model.description = params[:description]
      Audit.as_user(current_user) do 
        device_model.save!
      end  

      status 200
      present device_model
    end

  # desc "Set capabilty", {
  #   :notes => <<-NOTE
  #   The parameter capability takes an array. An example of the input is shown as follows:
  #  {
  #   "capability" : [ 
  #   { "parameter" : "zoom", "type" : "range" ,"control" : true,"value" : "1..100"},
  #   { "parameter" : "pan", "type" : "range" ,"control" : true,"value" : "1..10"}
  #     ] }

  #  * Value of type should be either of range, list, number or string within double quotes.
  #  * Values of parameter, value should be within double quotes.
  #  * Value of control should be either true or false within double quotes. 
  #  * control = false indicates for information purpose only and control = true indicates that the value can be changed.
   
  #    *** This query CANNOT be executed using Swagger framework. Please use some REST client (like Postman, or RESTClient etc.)
  #   NOTE
  # }
  # params do
  # requires :capability, :type => Array, :desc => "Device model capability. This takes a JSON array. See query notes for example."
  #  end 
  #  put ':model_no/set_capability' do
  #   authenticated_user

  #   device_model = DeviceModel.where(model_no: params[:model_no]).first
  #   not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

  #   forbidden_request! unless current_user.has_authorization_to?(:update, device_model)
   
  #   params[:capability].each do |capability|
  #    bad_request!(INVALID_CAPABILITY_FORMAT,"Parameter capability does not contain necessary fields.") unless (capability.respond_to?("parameter") && capability.respond_to?("type") && capability.respond_to?("control") && capability.respond_to?("value"))
  #    bad_request!(INVALID_CAPABILITY_FORMAT,"parameter should not be null.") if capability.parameter.is_empty?
  #    bad_request!(INVALID_CAPABILITY_FORMAT,"Type should be either of range, list, number or string.") unless capability.type.in?(["range","list","number","string"])
  #    bad_request!(INVALID_CAPABILITY_FORMAT,"Control should be either true or false within double quotes.") unless capability.control.in?(["true","false"])
  #    bad_request!(INVALID_CAPABILITY_FORMAT,"Value should not be null.") if capability.value.is_empty?
  #    if capability.type == "range"
  #     bad_request!(INVALID_CAPABILITY_FORMAT,"Invalid value format.") unless capability.value.match(/[0-9]+-[0-9]+/)
  #    elsif capability.type == "list"
  #      bad_request!(INVALID_CAPABILITY_FORMAT,"Invalid value format.") unless capability.value.match(/[^,\s][^\,]*[^,\s]*/)
         
  #   end
      
  # end

  #   device_model.capability = params[:capability]
  #   Audit.as_user(current_user) do 
  #     device_model.save!
  #   end  

  #   present device_model, with: DeviceModel::Entity

  #  end

   desc "Get audits related to a specific device_type "
    get ':model_no/audit'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceModel)

      device_model = DeviceModel.with_deleted.where(model_no: params[:model_no]).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

      forbidden_request! unless current_user.has_authorization_to?(:read_any, device_model)
      status 200
      device_model.audits
    end

    desc "Upload device master csv file."
    params do
      requires :file, :desc => "Device master csv file"
    end 


    post ':model_no/device_master' do 
      authenticated_user

      device_model = DeviceModel.where(model_no: params[:model_no]).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

      forbidden_request! unless current_user.has_authorization_to?(:create, DeviceMasterBatch)

      
      bad_request!(INVALID_FILE, "Invalid file") unless params[:file].respond_to?("filename")     
        
       
        
        # csv file

        name =  params[:file].filename
        directory = Settings.location_directory
        FileUtils.mkdir_p directory unless File.exist?(directory)
       
        # create the file path
        path = File.join(directory, name)   

        begin
         
          File.open(path, "w+") { |f| f.write(params[:file].tempfile.read) }

          results = import(path) do
              start_at_row 1
              [
                   registration_id,
                   mac_address,
                   firmware_version,
                   hardware_version,
                   time
              ]
          end
        rescue
            FileUtils.rm_rf(path)  
            bad_request!(INVALID_FILE, "Invalid file. Please upload only csv files.")   
        end  
       
        # begin error validation
        FileUtils.rm_rf(path) 
        device_model_nos = DeviceModel.all.map(&:model_no)
        device_master_registration_ids = DeviceMaster.all.map(&:registration_id) 
        device_master_mac_addresses = DeviceMaster.all.map(&:mac_address) 
        device_test_batch = []
        error_messages = []
        i=1
        results.each do |result|
          i = i+1
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Registration_id should not be null."} if (!result.registration_id )
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Time should not be null."} if (!result.time)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Mac address should not be null."} if (!result.mac_address)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Firmware Version should not be null."} if (!result.firmware_version)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Hardware Version should not be null."} if (!result.hardware_version)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Registration id already present in Device Master."} if device_master_registration_ids.include? result.registration_id
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Mac Address already present in Device Master."} if device_master_mac_addresses.include? result.mac_address
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Registration_id should be 26 characters."} if (!result.registration_id  || result.registration_id.length!=Settings.registration_id_length)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Mac address should be 12 characters."} if (!result.mac_address || result.mac_address.length!=Settings.mac_address_length)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Firmware Version should be in format xx.yy.zz or xx.yy."} if (!result.firmware_version || !result.firmware_version.match(/^\d+.\d+(.\d+)?$/))
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Hardware Version should be in format xx.yy.zz or xx.yy."} if (!result.hardware_version || !result.hardware_version.match(/^\d+.\d+(.\d+)?$/))
          begin
           result.time = DateTime.parse(result.time)  
          rescue
            error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Time should be in YYYYMMDDHHMM format."} 
          end 

          device_test_batch << JSON.parse(result.to_json)
        end
    
         registration_ids = []
         device_test_batch.each do |hash|  # Checking if there are duplicate parameters
            registration_ids << hash["registration_id"]
         end
          duplicates = registration_ids.group_by { |e| e }.select { |k, v| v.size > 1 }.map(&:first)
          error_messages << {:line => 0, :registration_id => duplicates, :error =>  "Duplicate registration ids ."} unless registration_ids.length == registration_ids.uniq.length  

          bad_request!(INVALID_CAPABILITY_FORMAT,error_messages) if error_messages.count>0
          
          
          device_master_batch = device_model.device_master_batches.new
          #User.stamper = current_user
          device_master_batch.file_name = params[:file].filename
          device_master_batch.save! 

          # save in db 
         results.each do |info|
          
          device = device_master_batch.device_master.new
          device.registration_id = info.registration_id
          device.mac_address = info.mac_address
          device.time = info.time
          device.firmware_version = info.firmware_version
          device.hardware_version = info.hardware_version
            device.save!
         end

        upload_test_report_to_s3(params[:file],params[:model_no]) 


        status 200
        "Done"
     
    end

    desc 'Set device_model capability by uploading csv file'
    params do 
        requires :model_no
        requires :firmware_prefix
        requires :file, :desc => "Device model capability csv file."
    end 
    post 'device_model_capability' do 
        authenticated_user

        device_model = DeviceModel.where(model_no: params[:model_no]).first
        not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model
        forbidden_request! unless current_user.has_authorization_to?(:update, device_model)

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
                 control,
                 value
            ]
        end
        rescue
            FileUtils.rm_rf(path)  
            bad_request!(INVALID_FILE, "Invalid file. Please upload only csv files.")   
        end  
        
        FileUtils.rm_rf(path)  
        device_type = DeviceType.where(id: device_model.device_type_id).first
        device_type_capability = device_type.capability
        type_capabilities = []
        device_type_capability.each do |capability|
          type_capabilities << capability["param"]
        end
        
        capabilities = []
        error_messages = []
        i=1
     results.each do |capability|
        
        i = i+1
        
     
    error_messages << {:line => i, :param => capability.param, :error =>  "Parameter should not be null."} if (!capability.param || capability.param.is_empty?)
    error_messages << {:line => i, :param => capability.param, :error => "Parameter is not having valid format."} unless (!capability.param || capability.param.match(/^[a-zA-Z0-9_]+$/))
    
    error_messages << {:line => i, :param => capability.param, :error =>  "Value should not be null."} if (!capability.value || capability.value.is_empty?) 
    error_messages << {:line => i, :param => capability.param, :error => "Control should be either true or false ."} unless (!capability.control || capability.control.in?(["true","false"]))
    error_messages << {:line => i, :param => capability.param, :error =>  "Device model capability provided not available in device type capability list."} unless type_capabilities.include? capability.param
    if capability.type == "range"
      error_messages << {:line => i, :param => capability.param, :error => "Invalid range value format:"+capability.value} unless (!capability.value || capability.value.match(/^-?[0-9]+..-?[0-9]+$/))
     elsif capability.type == "list"
        error_messages << {:line => i, :param => capability.param, :error => "Invalid list value format:"+capability.value} unless (!capability.value || capability.value.match(/[^,\s][^\,]*[^,\s]*/))
     elsif capability.type == "number"
        error_messages << {:line => i, :param => capability.param, :error => " Invalid number value format:"+capability.value} unless (!capability.value || capability.value.match(/^-?[0-9]+$/)) 
    elsif capability.type == "bool"
        error_messages << {:line => i, :param => capability.param, :error => " Invalid bool value format:"+capability.value} unless (!capability.value || capability.value.in?(["true","false"]))
    elsif capability.type == "string"
    else
       error_messages << {:line => i, :param => capability.param, :error => "Type should be either of range, list, number, bool or string."}      
    end


    capabilities << JSON.parse(capability.to_json)
  end
  
    
     parameters = []
     capabilities.each do |hash|  # Checking if there are duplicate parameters
        parameters << hash["param"]
     end  
      error_messages << {:line => 0, :param => "NA", :error => "Device type capability provided has duplicate parameters."} unless parameters.length == parameters.uniq.length      
      bad_request!(INVALID_CAPABILITY_FORMAT,error_messages) if error_messages.count>0
      model_capability = device_model.device_model_capabilities.new
      model_capability.firmware_prefix = params[:firmware_prefix]
      model_capability.capability = capabilities
      
      Audit.as_user(current_user) do 
        model_capability.save!
      end  
      upload_capability_to_s3(params[:file],params[:firmware_prefix])
      status 200
      present model_capability, with: DeviceModelCapability::Entity

    end

    desc "Get the list of device master batches for particular model."  
    get ':model_no/batches' do
    authenticated_user
    status 200

    device_model = DeviceModel.where(model_no: params[:model_no]).first
    not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

    forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceMasterBatch)

    batches = device_model.device_master_batches.where(device_model_id: device_model.id)

    batches.each do |batch|
      creator = User.with_deleted.where(id: batch.creator_id).first
      batch.creator = creator.name if creator
    end  

    

    present batches,  with: DeviceMasterBatch::Entity
  end


    desc "Get the list of devices  particular batch."  
    get ':batch_id/devices' do
    authenticated_user
    status 200

    device_masters = DeviceMaster.where(device_master_batch_id: params[:batch_id])
    not_found!(MODEL_NOT_FOUND, "DeviceMaster: " + params[:batch_id].to_s) if device_masters.empty?

    forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceMasterBatch)

    present device_masters,  with: DeviceMaster::Entity
  end


  end
end    
