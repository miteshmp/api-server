require 'grape'
require 'json'
require 'chronic_duration'
require 'chronic'
require 'error_format_helpers'

class DevicesCookerAPI_v1 < Grape::API
  include Audited::Adapters::ActiveRecord
  format :json
  # version 'v1', :using => :path, :format => :json
  formatter :json, SuccessFormatter
  default_format :json

  params do
    optional :suppress_response_codes, type: Boolean, :desc => "Suppress response codes"
  end

  resource :devices do

    # Sends the cooking command (A0) to a cooker
    desc "Start cooking"
    params do
      requires :program_code, :type => Integer, :desc => "The program code for recipe"
      optional :enable_keep_warm, type: Boolean, default: false, :desc => "Enable keep warm function after cooking (false by default)"
      optional :cook_hour, :type => Integer, validvalue: 0..11, default: 0, :desc => "Cook time in hours (if this value is not specified, then it will use the recipe's default cook time)"
      optional :cook_min, :type => Integer, validvalue: 0..59, default: 0, :desc => "Cook time in minutes (if this value is not specified, then it will use the recipe's default cook time)"
      optional :temperature, :type => Integer, validvalue: 35..179, default: 35, :desc => "Cook temperature in Celsius"
    end
    post 'cooker/:registration_id/start_cook' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      recipe = Recipe.where(program_code: params[:program_code]).first()
      not_found!(TYPE_NOT_FOUND, "Recipe with program_code: " + params[:program_code].to_s) unless recipe
      Rails.logger.info "Recipe to be cooked is: #{recipe.default_duration}"
      if (params[:cook_hour] == 0 && params[:cook_min] == 0)
        secs = ChronicDuration::parse(recipe.default_duration, :minutes => true)
        if (secs.blank?)
          bad_request!(INVALID_REQUEST, "The selected program_code #{params[:program_code]} has no default cook time. Please specify cook_hour/cook_min!")
        end
        mins = secs > 0 ? secs/60 : 0
        Rails.logger.info "debugged #{secs}"
        if (mins > 0 && mins > 59)
          params[:cook_hour] = mins/60
          params[:cook_min] = mins%60
        else
          params[:cook_hour] = 0
          params[:cook_min] = mins
        end
        Rails.logger.info "Parsed default duration for the recipe #{params[:cook_hour]} and min: #{params[:cook_min]}"
      end
      temperature = params[:temperature] ? params[:temperature].to_i : TatungConfiguration::DEFAULT_COOKING_TEMPERATURE ;
      cook_command = Settings.cooker_commands.send_command % cook_command(params[:program_code], params[:cook_hour], params[:cook_min], params[:enable_keep_warm] ? 1 : 0, temperature,true)
      Rails.logger.info "Cook command is: #{cook_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, cook_command))
      parsed_response[0]
    end

    # Sends the warming command (A1) to a cooker
    desc "Start warming"
    params do
      requires :reheat_hour, :type => Integer, validvalue: 0..23, default: 0, :desc => "Reheat time in hours"
      requires :reheat_min,  :type => Integer, validvalue: 0..59, default: 0, :desc => "Reheat time in minutes"
    end
    post 'cooker/:registration_id/start_warming' do
      active_user = authenticated_user ;
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless active_user.has_authorization_to?(:send_command, device)
      reheat_command = Settings.cooker_commands.send_command % reheat_command( params[:reheat_hour], params[:reheat_min] );
      parsed_response = parse_stun_response(send_command_over_stun(device, reheat_command))
      parsed_response[0]
    end


    # Sends the stop/cancel command (A5) to a cooker
    desc "Cancel all tasks"
    post 'cooker/:registration_id/cancel_all_tasks' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      cancel_command = Settings.cooker_commands.send_command % hex_to_base64(Settings.cooker_commands.cancel_all_command)
      Rails.logger.info "cancel_command command is: #{cancel_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, cancel_command))
      status_response = parse_cancel_response(parsed_response[1])
    end

    # Sends the Get status command (A6) to a cooker
    desc "Get status_command of cooker"
    get 'cooker/:registration_id/status' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      status_command = Settings.cooker_commands.send_command % hex_to_base64(Settings.cooker_commands.get_status_command)
      Rails.logger.info "get_status command is: #{status_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, status_command))
      status_data = parse_status_response(parsed_response[1])
      recipe = ""
      if (!status_data.program_code.blank?)
        recipe = Recipe.where(program_code: status_data.program_code).first()
      end
      status 200
      {
        "cooker_status" => status_data,
        "recipe" => recipe
      }
    end

    # Sends the Set clock command (A2) to a cooker
    desc "Set cooker clock"
    params do
      requires :date_time, :type => String, :desc => "clock time (eg., 03/01/2012 07:25:09)"
    end
    post 'cooker/:registration_id/set_clock' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      parsed_time = Chronic.parse(params[:date_time])
      if (!parsed_time)
        bad_request!(INVALID_REQUEST, "The input format for date_time must be like 03/01/2012 07:25:09. Please try again with proper date_time input!")
      end
      # TODO: verify if day of week starts from 0 for the cooker from FW team
      Rails.logger.info "Parsed chronic timee object year: #{parsed_time.year}, month: #{parsed_time.month}, day: #{parsed_time.day}, hr: #{parsed_time.hour}, min: #{parsed_time.min}, sec: #{parsed_time.sec}, day of week: #{parsed_time.wday}"
      clock_command = Settings.cooker_commands.send_command % set_cooker_clock(parsed_time.year, parsed_time.month, parsed_time.wday, parsed_time.day, parsed_time.hour, parsed_time.min, parsed_time.sec)
      Rails.logger.info "clock_command command is: #{clock_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, clock_command))
      parsed_response[0]
    end

    # Sends the preset command (A3) to a cooker
    desc "Schedule the cooker to cook a recipe"
    params do
      requires :program_code, :type => Integer, :desc => "The program code for recipe"
      requires :delay_hour, type: Integer, validvalue: 0..23, default: false, :desc => "The hour by which cooking needs to be finished"
      requires :delay_min, type: Integer, validvalue: 0..59, default: false, :desc => "The min by which cooking needs to be finished"
      optional :cook_hour, :type => Integer, validvalue: 0..11, default: 0, :desc => "Cook time in hours (if this value is not specified, then it will use the recipe's default cook time)"
      optional :cook_min, :type => Integer, validvalue: 0..59, default: 0, :desc => "Cook time in minutes (if this value is not specified, then it will use the recipe's default cook time)"
      optional :temperature, :type => Integer, validvalue: 35..179, default: 35, :desc => "Cook temperature in Celsius"
      optional :enable_keep_warm, type: Boolean, default: false, :desc => "Enable keep warm function after cooking (false by default)"
    end
    post 'cooker/:registration_id/schedule_cooking' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      recipe = Recipe.where(program_code: params[:program_code]).first()
      not_found!(TYPE_NOT_FOUND, "Recipe with program_code: " + params[:program_code].to_s) unless recipe
      Rails.logger.info "Recipe to be cooked is: #{recipe.default_duration}"
      if (params[:cook_hour] == 0 && params[:cook_min] == 0)
        secs = ChronicDuration::parse(recipe.default_duration, :minutes => true)
        if (secs.blank?)
          bad_request!(INVALID_REQUEST, "The selected program_code #{params[:program_code]} has no default cook time. Please specify cook_hour/cook_min!")
        end
        mins = secs > 0 ? secs/60 : 0
        if (mins > 0 && mins > 59)
          params[:cook_hour] = mins/60
          params[:cook_min] = mins%60
        else
          params[:cook_hour] = 0
          params[:cook_min] = mins
        end
      end
      temperature = params[:temperature] ? params[:temperature].to_i : TatungConfiguration::DEFAULT_COOKING_TEMPERATURE ;
      preset_command = Settings.cooker_commands.send_command % preset_cook(params[:program_code], params[:delay_hour], params[:delay_min], params[:cook_hour], params[:cook_min],temperature,params[:enable_keep_warm] ? 1 : 0)
      Rails.logger.info "Preset command is: #{preset_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, preset_command))
      parsed_response[0]
    end

    # Sends the change settings command (AA) to a cooker
    desc "Change settings while cooking"
    params do
      requires :program_code, :type => Integer, :desc => "The program code for recipe"
      requires :enable_keep_warm, type: Boolean, default: false, :desc => "Enable keep warm function after cooking (false by default)"
      requires :cook_hour, :type => Integer, validvalue: 0..11, default: 0, :desc => "Cook time in hours (if this value is not specified, then it will use the recipe's default cook time)"
      requires :cook_min, :type => Integer, validvalue: 0..59, default: 0, :desc => "Cook time in minutes (if this value is not specified, then it will use the recipe's default cook time)"
      requires :temperature, :type => Integer, validvalue: 35..179, default: 35, :desc => "Cook temperature in Celsius"
    end
    put 'cooker/:registration_id/alter_current_cook' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      recipe = Recipe.where(program_code: params[:program_code]).first()
      not_found!(TYPE_NOT_FOUND, "Recipe with program_code: " + params[:program_code].to_s) unless recipe
      Rails.logger.info "Recipe to be cooked is: #{recipe.default_duration}"
      if (params[:cook_hour] == 0 && params[:cook_min] == 0)
        secs = ChronicDuration::parse(recipe.default_duration, :minutes => true)
        if (secs.blank?)
          bad_request!(INVALID_REQUEST, "The selected program_code #{params[:program_code]} has no default cook time. Please specify cook_hour/cook_min!")
        end
        mins = secs > 0 ? secs/60 : 0
        Rails.logger.info "debugged #{secs}"
        if (mins > 0 && mins > 59)
          params[:cook_hour] = mins/60
          params[:cook_min] = mins%60
        else
          params[:cook_hour] = 0
          params[:cook_min] = mins
        end
      end
      temperature = params[:temperature] ? params[:temperature].to_i : TatungConfiguration::DEFAULT_COOKER_TEMPERATURE ;
      cook_command = Settings.cooker_commands.send_command % cook_command(params[:program_code], params[:cook_hour], params[:cook_min], params[:enable_keep_warm] ? 1 : 0,temperature, false);
      Rails.logger.info "Cook command is: #{cook_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, cook_command))
      parsed_response[0]
    end

    # Sends the user defined program command (A9) to a cooker
    desc "Set user defined program", {
      :notes => <<-NOTE
      The parameter user_program takes an array of cooking steps (upto 9 steps). Each step has a cooking hour, min, temperature fields. An example is shown below
      {
        "user_program" : [
          {"hour":1, "min":10, "temperature":80},
          {"hour":2, "min":30, "temperature":120},
          {"hour":3, "min":45, "temperature":130},
          {"hour":0, "min":25, "temperature":20}
        ]
      }
      NOTE
    }
    params do
      requires :user_program, :type => Array , :desc => "User defined set of cooking steps. Expects a JSON array. See query notes for example."
    end
    post 'cooker/:registration_id/cook_user_program' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      user_program_array = get_empty_user_program()
      params[:user_program].each_with_index do |program, index|
        exist_prog = user_program_array[index]
        exist_prog.hour = program.hour
        exist_prog.minute = program.minute
        exist_prog.temperature = program.temperature
        user_program_array[index] = exist_prog
      end
      stage1 = user_program_command(user_program_array[0..2])
      stage2 = user_program_command(user_program_array[3..5])
      stage3 = user_program_command(user_program_array[6..8])
      user_cook_cmnd = Settings.cooker_commands.send_command % stage1 + ";" + stage2 + ";" + stage3
      parsed_response = parse_stun_response(send_command_over_stun(device, user_cook_cmnd))
      parsed_response[0]
    end

    desc "Get user defined program parameters from cooker"
    get 'cooker/:registration_id/cook_user_program' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      status_command = Settings.cooker_commands.send_command % hex_to_base64(Settings.cooker_commands.user_program_command)
      Rails.logger.info "get_status command is: #{status_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, status_command))
      user_program = parse_user_program_response(parsed_response[1])
      status 200
      {
        "user_program" => user_program,
      }
    end

    # Parses a recipe from a 3rd paty source (only allrecipes.com supported for now)
    # and constructs & sends a user defined program command (A9) to a cooker
    desc "Cook recipe from a third-party"
    params do
      requires :recipe_url, :type => String , :desc => "Third party source url for the recipe"
    end
    post 'cooker/:registration_id/cook_other_recipe' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      begin
        uri = URI.parse(params[:recipe_url])
        if (!params[:recipe_url].include? "allrecipes")
          bad_request!(INVALID_REQUEST, "Only recipes from allrecipes.com are supported at the moment!")
        end
      rescue URI::InvalidURIError => e
        bad_request!(INVALID_REQUEST, "Invalid input url #{params[:recipe_url]}.")
      end
      user_program_array = parse_other_url(params[:recipe_url])
      if (!user_program_array.blank? && user_program_array.length == 9)
        stage1 = user_program_command(user_program_array[0..2])
        stage2 = user_program_command(user_program_array[3..5])
        stage3 = user_program_command(user_program_array[6..8])
        user_cook_cmnd = Settings.cooker_commands.send_command % stage1 + ";" + stage2 + ";" + stage3
        parsed_response = parse_stun_response(send_command_over_stun(device, user_cook_cmnd))
      end
      parsed_response[0]
    end

    # Sends the wireless status command (AB) to a cooker
    desc "Get connection status"
    post 'cooker/:registration_id/connection' do
      authenticated_user
      device = Device.where(registration_id: params[:registration_id]).first
      not_found!(DEVICE_NOT_FOUND, "Device: " + params[:registration_id].to_s) unless device
      forbidden_request! unless current_user.has_authorization_to?(:send_command, device)
      cancel_command = Settings.cooker_commands.send_command % hex_to_base64(Settings.cooker_commands.wireless_status_command)
      Rails.logger.info "wireless_status command is: #{cancel_command}"
      parsed_response = parse_stun_response(send_command_over_stun(device, cancel_command))
      Rails.logger.info "wireless_status response: #{parsed_response}"
      status_response = parse_wireless_response(parsed_response[1])
    end

    # Sends cooker related notifications to users
    desc "Push cooker notifications"
    params do
      requires :auth_token, :type => String, :desc => "Device's auth token"
      requires :alert_code, :type => Integer, :desc => "The alert code for notification"
      requires :alert_value, :type => String, :desc => "The notification value that needs to be sent "
    end
    post 'cooker/notifications' do
      active_device  = authenticated_device(true) ;
      user = User.where(id: active_device.user_id).first
      not_found!(USER_NOT_FOUND, "User: " + active_device.user_id.to_s) unless user
      
    end

  end

end
