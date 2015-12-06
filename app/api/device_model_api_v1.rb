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

  # Resource :- device_models

  resource :device_models do

    desc "Register a new model "
    params do
      requires :type_code, :type => String, :desc => "Type code"
      requires :name, :type => String, :desc => "Specific model name"
      requires :model_no, :type => String, :desc => "Model code"
      requires :udid_scheme, :type => Integer, :desc => "UDID scheme. 1 for Monitor Device Type and 2 for Desktop device type"
      requires :description , :type =>String, :desc =>"Model description"
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
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
      model.tenant_id = params[:tenant_id] if params[:tenant_id].present?
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
      device_models = params[:q] ? search_result.result(distinct: true) : DeviceModel.includes(:device_model_capabilities)
      
      present device_models.paginate(:page => params[:page], :per_page => params[:size])  , with: DeviceModel::Entity

    end

    desc "Get the list of devices in device master." 
    params do
      group :q do
      optional :device_master_batch_id_eq
    end
    end 
    get 'devices' do
    authenticated_user
    status 200

    forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceMasterBatch)

    search_result = DeviceMaster.search(params[:q])
    device_masters = params[:q] ? search_result.result(distinct: true) : DeviceMaster
      
    present device_masters.paginate(:page => params[:page], :per_page => params[:size])  , with: DeviceMaster::Entity
  end

    

    desc "Get a specific device model"
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		end
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
      optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
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
   params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		end
    get ':model_no/audit'  do
      authenticated_user
      forbidden_request! unless current_user.has_authorization_to?(:read_any, DeviceModel)

      device_model = DeviceModel.with_deleted.where(model_no: params[:model_no]).first
      not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model

      forbidden_request! unless current_user.has_authorization_to?(:read_any, device_model)
      status 200
      device_model.audits
    end


    # Query :- Upload device master csv file for device Master
    # Method :- POST
    # Parameters :-
    #         model_no  :- Device Model No
    #         file :- Device Batch file
    # Response :-
    #         Return status message about uploading master batch file
    desc "Upload device master csv file."

      params do
        requires :file, :desc => "Device master csv file"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
      end

      post ':model_no/device_master' do 

        active_user = authenticated_user ;

        device_model = DeviceModel.where(model_no: params[:model_no]).first ;
        not_found!(MODEL_NOT_FOUND, "DeviceModel: " + params[:model_no].to_s) unless device_model ;

        forbidden_request! unless active_user.has_authorization_to?(:create, DeviceMasterBatch) ;
        bad_request!(INVALID_FILE, "Invalid file") unless params[:file].respond_to?("filename") ;

        # define number of thread
        NO_OF_VERIFICATION_THREAD = 5;

        NO_OF_DATABASE_THREAD = 5;

        # Get CSV file which is given by factory_user
        name =  params[:file].filename ;
        directory = Settings.location_directory ;
        FileUtils.mkdir_p directory unless File.exist?(directory) ;
       

        # Create the File Path
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
                   time,
                   serial_number
              ]
          end

        rescue
            FileUtils.rm_rf(path)  
            bad_request!(INVALID_FILE, "Invalid file. Please upload only csv files.")   
        end  
       
        # Delete File
        FileUtils.rm_rf(path) 

        device_model_nos = DeviceModel.all.map(&:model_no)
        device_master_registration_ids = DeviceMaster.pluck(:registration_id) ;
        device_master_mac_addresses = DeviceMaster.pluck(:mac_address) ;

        # contains error message which is shared between threads
        error_messages = [] 

        # Require mutex to avoid data corruption on "error_messages"
        verification_thread_semaphore = Mutex.new ;

        # store all thread which are used for verification
        results_verification_thread = [] ;
        
        # array slice number
        VERIFY_ARRAY_SLICE_NUMBER =  ( (results.size / NO_OF_VERIFICATION_THREAD.to_f).round != 0 )  ? (results.size/NO_OF_VERIFICATION_THREAD.to_f).round : results.size ;

        # split array for verification
        split_verification_results = results.each_slice(VERIFY_ARRAY_SLICE_NUMBER).to_a ;

        verification_loop_counter = 0 ;

        split_verification_results.each do |split_verification_result|

          split_array_size = split_verification_result.size ;

          results_verification_thread << Thread.new(array_counter=verification_loop_counter,thread_array_size=split_array_size) {

            begin
            
              ActiveRecord::Base.connection_pool.with_connection do

                thread_counter = 0;

                split_verification_result.each do |device_item_result|

                  line_number = (array_counter * thread_array_size + thread_counter ) + 1;

                  # verify that "device_item_result" contains null or not.
                  if device_item_result.values_at(0..4).include? nil

                    verification_thread_semaphore.synchronize {
                      error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Any parameter should  not be null."}
                    }

                  end

                  # verify registration ID
                  if device_master_registration_ids.include? device_item_result.registration_id

                    verification_thread_semaphore.synchronize {
                      error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Registration id already present in Device Master."} ;
                    }
                  end

                  #  verify MAC address
                  if device_master_mac_addresses.include? device_item_result.mac_address

                    verification_thread_semaphore.synchronize {
                      error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Mac Address already present in Device Master."} ;
                    }
                  end

                  # verify length for registration id
                  if (!device_item_result.registration_id  || device_item_result.registration_id.length != Settings.registration_id_length )

                    verification_thread_semaphore.synchronize {
                      error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Registration_id should be 26 characters."} ;
                    }
                  end

                  # verify length for MAC Address
                  if (!device_item_result.mac_address || device_item_result.mac_address.length != Settings.mac_address_length)
                
                    verification_thread_semaphore.synchronize {
                      error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Mac address should be 12 characters."} ;
                    }
                  end

                  # verify firmware version
                  if (!device_item_result.firmware_version || !device_item_result.firmware_version.match(/^\d+.\d+(.\d+)?$/))
                  
                    verification_thread_semaphore.synchronize {
                      error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Firmware Version should be in format xx.yy.zz or xx.yy."} ;
                    }
                  end
              
                  begin
               
                    device_item_result.time = DateTime.parse(device_item_result.time) ;
                    rescue
                      verification_thread_semaphore.synchronize {
                        error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Time should be in YYYYMMDDHHMM format."} ;
                      }
                  end

                  thread_counter = thread_counter + 1;
              
                end # split_verification_result 
          
              end  # active_connection

              rescue Exception => exception
                Rails.logger.error " * Exception occured ::- #{exception.message}" ;
                  verification_thread_semaphore.synchronize {
                    error_messages << {:line => line_number, :registration_id => device_item_result.registration_id, :error =>  "Exception occurred :- please upload again"}  ;
                  }
                
                ensure
                  ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                  ActiveRecord::Base.clear_active_connections! ;
                
            end # Begin

          } # thread completed

          verification_loop_counter = verification_loop_counter + 1;
        
        end

        # make sure that each thread has completed its task
        results_verification_thread.each { |verification_thread| verification_thread.join } ;

        # clear stalge cached connection
        ActiveRecord::Base.connection_pool.clear_stale_cached_connections! ;

        # Validate Uploaded device master batch file
=begin
        results.each do |result|

          i = i+1
          if result.values_at(0..4).include? nil
            error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Any parameter should  not be null."}
          end
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Registration id already present in Device Master."} if device_master_registration_ids.include? result.registration_id
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Mac Address already present in Device Master."} if device_master_mac_addresses.include? result.mac_address
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Registration_id should be 26 characters."} if (!result.registration_id  || result.registration_id.length!=Settings.registration_id_length)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Mac address should be 12 characters."} if (!result.mac_address || result.mac_address.length!=Settings.mac_address_length)
          error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Firmware Version should be in format xx.yy.zz or xx.yy."} if (!result.firmware_version || !result.firmware_version.match(/^\d+.\d+(.\d+)?$/))
        
          begin
            result.time = DateTime.parse(result.time) ;
            rescue
              error_messages << {:line => i, :registration_id => result.registration_id, :error =>  "Time should be in YYYYMMDDHHMM format."} 
          end
        
        end
=end
        # considered bad request if verification failed
        bad_request!(INVALID_CAPABILITY_FORMAT,error_messages) if ( error_messages.count > 0 ) ;


        # delete duplicate entry from results
        duplicate_record = results.uniq! ;
      
        # possible that record does not have duplicate entry, but registration id and mac_address
        # has individual duplicate entry
        duplicate_registration_id = results.group_by { |result| result.registration_id }.select { |k, v| v.size > 1 }.map(&:first) ;

        if  ( duplicate_registration_id && duplicate_registration_id.length > 0)
          
          error_messages << {:line => 0, :registration_id => duplicate_registration_id, :error =>  "Duplicate registration ids ."} 
          bad_request!(INVALID_CAPABILITY_FORMAT,error_messages) if ( error_messages.count > 0 )
        
        end

        duplicate_mac_address = results.group_by { |result| result.mac_address }.select { |k, v| v.size > 1 }.map(&:first) ;
        
        if ( duplicate_mac_address && duplicate_mac_address.length > 0)
          
          error_messages << {:line => 0, :mac_address => duplicate_mac_address, :error =>  "Duplicate MAC Address :-"} 
          bad_request!(INVALID_CAPABILITY_FORMAT,error_messages) if ( error_messages.count > 0 )
        
        end
        
        # Store file informaton in "device_master_batch" table
        device_master_batch = device_model.device_master_batches.new
        
        #User.stamper = current_user
        device_master_batch.file_name = params[:file].filename
        device_master_batch.save!

        # database array slice number
        DATABASE_ARRAY_SLICE_NUMBER = ( ((results.size / NO_OF_DATABASE_THREAD.to_f).round ) != 0 ) ? (results.size / NO_OF_DATABASE_THREAD.to_f).round : results.size ;

        # save device udid information in device master
        results_database_thread = [] ;

        split_database_results = results.each_slice(DATABASE_ARRAY_SLICE_NUMBER).to_a ;

        # store device udid information into database using thread
        split_database_results.each do |split_database_array|

          results_database_thread << Thread.new {

            ActiveRecord::Base.connection_pool.with_connection do
            
              begin
              
                split_database_array.each do |device_info|

                  device = device_master_batch.device_master.new
                  
                  device.registration_id = device_info.registration_id ;
                  device.mac_address = device_info.mac_address ;
                  device.time = device_info.time ;
                  device.firmware_version = device_info.firmware_version ;
                  device.hardware_version = device_info.hardware_version ;

                  if device_info.serial_number
                    device.serial_number = device_info.serial_number ;
                  else
                    device.serial_number = 0; # default value
                  end

                  # store result in device master 
                  device.save!    
       
                end # split_database_array do..while 
              
              rescue Exception => exception
                Rails.logger.error "\n * Exception occured ::- #{exception.message}" ;
                verification_thread_semaphore.synchronize {
                  error_messages << {:registration_id => device_info.registration_id, :error =>  "Database operation failed"}  ;
                }
                  
              ensure
                ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                ActiveRecord::Base.clear_active_connections! ;
              end
            
            end # active_record connection
          }
        end # split_database_results loop
        
        
        results_database_thread.each { |database_thread| database_thread.join } ;
        
        bad_request!(INVALID_CAPABILITY_FORMAT,error_messages) if ( error_messages.count > 0 ) ;


        # Upload test file into S3 for future reference
        Thread.new {

          ActiveRecord::Base.connection_pool.with_connection do
            
            begin
            
             upload_test_report_to_s3(params[:file],params[:model_no]);
            
              rescue Exception => exception
              ensure
                ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                ActiveRecord::Base.clear_active_connections! ;
            end
          
          end
        }

        status 200
        "Done"    
      
      end
    # Complete query :- "upload device master  csv file "

    desc 'Update Device Registration ID in Device Master File'

      params do

        requires :mac_address, :desc => "Device MAC Address"
        optional :registration_id, :desc => "Update device registration ID"
        optional :firmware_version, :desc => "Update device firmware detail"
        optional :hardware_version, :desc => "Hardware version"
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"

      end

      post 'update_device_master' do

        active_user = authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:update, DeviceMasterBatch) ;

        device = Device.with_deleted.where(mac_address: params[:mac_address]).first ;

        if device

          # device mac address is already present in device table. so it is difficult to
          # update any information in device master batch table.
          status 200
          {
            :update_status => false,
            :registration_id => device.registration_id,
            :mac_address => device.mac_address,
            :firmware_version => device.firmware_version
          }

        else

          device_master = DeviceMaster.where(mac_address: params[:mac_address]).first ;
          not_found!(MAC_ADDRESS_NOT_FOUND_IN_DEVICE_MASTER, "Device MAC Address :- " + params[:mac_address].to_s) unless device_master ;

          if params[:registration_id]

            invalid_parameter!("registration_id") unless params[:registration_id].length == Settings.registration_id_length

            device_type_code   = params[:registration_id][0..1];
            device_model_no    = params[:registration_id][2..5];
            device_mac_address = params[:registration_id][6..17];

            device_type = DeviceType.where(type_code: device_type_code).first ;
            not_found!(TYPE_NOT_FOUND,"DeviceType: " + device_type_code.to_s) unless device_type

            device_model = DeviceModel.where(model_no: device_model_no).first ;
            not_found!(MODEL_NOT_FOUND, "DeviceModel: " + device_model_no.to_s) unless device_model

            if params[:mac_address] != device_mac_address

              invalid_parameter!("registration_id") ;

            end

            device_master.registration_id = params[:registration_id] ;

          end

          if params[:firmware_version]

            if !(params[:firmware_version].match(/^\d+.\d+(.\d+)?$/))

              invalid_parameter!("firmware_version") ;
            end

            device_master.firmware_version = params[:firmware_version] if params[:firmware_version] ;
          end

          device_master.hardware_version = params[:hardware_version] if params[:hardware_version] ;

          begin

            device_master.save! ;
            rescue Exception => exception
              internal_error!(DATABASE_VALIDATION_ERROR,HubbleErrorMessage::DATABASE_ERROR_MESSAGE);
          end

          status 200
          {
            :update_status => true,
            :registration_id => device_master.registration_id,
            :mac_address => device_master.mac_address,
            :firmware_version => device_master.firmware_version,
            :hardware_version => device_master.hardware_version
          }

        end

      end
    # Complete :- "Update Device Registration ID in Device Master File"

    desc 'Set device_model capability by uploading csv file'
    params do 
        requires :model_no
        requires :firmware_prefix
        requires :file, :desc => "Device model capability csv file."
        optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
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
    params do
			optional :tenant_id, :type => Integer, :desc => "Tenant id is used to know the type of client(Binatone,Vtech,Connect,etc)"
		end
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


    


  end
end    
