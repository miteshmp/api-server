require 'time_difference'
require 'chronic_duration'
require 'nokogiri'

module CookerHelper

  class Duration
    attr_accessor :hr, :min
  end

  COOKER_STATUSES = ['standby', 'cooking', 'keep_warm', 'waiting_to_cook']
  COOKER_ERROR = ['none', 'top_temperature_sensor_open', 'top_temperature_sensor_short', 'bottom_temperature_sensor_open', 'bottom_temperature_sensor_short']
  COOKER_CONNECTION = ['wireless_disconnected', 'wireless_connection_in_progress', 'wireless_connected']

  def cook_command(prog_number, cook_hr, cook_min, keep_warm,temperature, start_new)
    cook_head = Settings.cooker_commands.start_cook_head
    if (!start_new)
      cook_head = Settings.cooker_commands.alter_cook_head
    end
    hex_array = get_hex_array(prog_number, cook_hr, cook_min, temperature, keep_warm)
    cook_command = cook_head + hex_array.join('')
    get_base64_command(cook_command, cook_head, *hex_array)
  end

  def reheat_command(warm_hr, warm_min)

    reheat_head = Settings.cooker_commands.start_reheat_head

    hex_array = get_hex_array(warm_hr,warm_min)
    
    reheat_command = reheat_head + hex_array.join('') ;

    get_base64_command(reheat_command, reheat_head, *hex_array)
  
  end

  def set_cooker_clock(year, month, day_of_week, date, hr, min, sec)
    year = year.to_s(16).rjust(4, '0')
    set_clock_head = Settings.cooker_commands.set_clock_head
    hex_array = get_hex_array(month, day_of_week, date, hr, min, sec)
    clock_command = set_clock_head + year[0..1] + year[2..3] + hex_array.join('')
    get_base64_command(clock_command, set_clock_head, year[0..1], year[2..3], *hex_array)
  end

  def preset_cook(prog_number, delay_hr, delay_min, cook_hr, cook_min,temperature, keep_warm)
    preset_head = Settings.cooker_commands.preset_head
    hex_array = get_hex_array(prog_number, delay_hr, delay_min, cook_hr, cook_min, temperature, keep_warm)
    preset_command = preset_head + hex_array.join('')
    get_base64_command(preset_command, preset_head, *hex_array)
  end

  def get_product_identifier()
    pid_command = Settings.cooker_commands.get_product_identifier
    hex_to_base64(pid_command)
  end

  def parse_user_program_response(program)
    # program = "fg2yAQIAUAICAFADAgBQAaV6;fg2yBAIAUAUAAAAGAAAAAQp6;fg2yBwAAAAgAAAAJAAAAAMF6"
    Rails.logger.info "User Program value from device is: #{program}"
    response = Array.new
    if (!program.blank?)
      split_response = program.split(';')
      if (split_response && split_response.length == 3)
        i = 6
        split_response.each do |resp|
          hex_resp = base64_to_hex(resp)
          if (hex_resp.length > 26 && (Settings.cooker_commands.slave_user_program_head.casecmp(hex_resp[4..5]) == 0))
            has_reserve = hex_resp[2..3].casecmp("0D") != 0
            stage1 = create_user_program(hex_resp, has_reserve, 5)
            stage2 = create_user_program(hex_resp, has_reserve, stage1[1])
            stage3 = create_user_program(hex_resp, has_reserve, stage2[1])
            response.push(stage1[0], stage2[0], stage3[0])
          end
        end
      end
      response
    end
  end

  def create_user_program(input, has_reserve, counter)
    Rails.logger.info "user_program: #{input}"
    result = Array.new
    program = CookerUserProgram.new
    i = counter
    program.step = input[(i+=1)..(i+=1)].to_i(16)
    program.hour = input[(i+=1)..(i+=1)].to_i(16)
    program.minute = input[(i+=1)..(i+=1)].to_i(16)
    hex_temp = input[(i+=1)..(i+=1)]
    temp_i = hex_temp.to_i(16)
    if (has_reserve && hex_temp)
      temp_2 = handle_reserve_bytes(hex_temp, input[(i+1)..(i+1)])
      if (temp_2 > 0)
        temp_i += temp_2
        i += 2
      end
    end
    program.temperature = temp_i
    result.push(program, i)
    result
  end

  def parse_status_response(response)
    cooker_status = CookerStatus.new
    if (!response.blank? && (response.include? ";"))
      split_response = response.split(';')
      cooker_status = parse_status(split_response[0])
    else
      cooker_status = parse_status(response)
    end
    cooker_status
  end

  def parse_wireless_response(response)
    status_hex = base64_to_hex(response)
    Rails.logger.info "wireless status: #{status_hex}"
    # COOKER_CONNECTION
  end

  def parse_status(status)
    # TODO: Parse the second part of response for ack
    if (!status.blank?)
      status_hex = base64_to_hex(status)
      cooker_status = CookerStatus.new
      Rails.logger.info "Status from device is: #{status_hex}"
      if (status_hex.length > 33 && (Settings.cooker_commands.slave_status_head.casecmp(status_hex[4..5]) == 0))
        has_reserve_bytes = false
        if (status_hex[2..3].to_i(16) > 14)
          has_reserve_bytes = true
        end
        i = 6
        cooker_status.program_code = status_hex[i..(i+=1)].to_i(16)
        cooker_status.status = COOKER_STATUSES[status_hex[(i+=1)..(i+=1)].to_i(16)]
        target_temp_hex = status_hex[(i+=1)..(i+=1)]
        target_temp = target_temp_hex.to_i(16)
        instant_temp = 0
        if (has_reserve_bytes)
          if (target_temp_hex.casecmp(Settings.cooker_commands.reserve_byte)==0)
            target_temp += handle_reserve_bytes(status_hex[(i+=1)..(i+=1)])
            inst_temp_hex = status_hex[(i+=1)..(i+=1)]
            instant_temp = inst_temp_hex.to_i(16)
            if (inst_temp_hex.casecmp(Settings.cooker_commands.reserve_byte)==0)
              instant_temp += handle_reserve_bytes(status_hex[(i+=1)..(i+=1)])
            end
          end
        else
          instant_temp += status_hex[(i+=1)..(i+=1)].to_i(16)
        end
        cooker_status.target_temperature = target_temp
        cooker_status.instant_temperature = instant_temp
        cooker_status.cooker_clock_hr = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.cooker_clock_min = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.keep_warm_hr = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.keep_warm_min = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.cook_start_hr = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.cook_start_min = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.cook_stop_hr = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.cook_stop_min = handle_invalid_value(status_hex[(i+=1)..(i+=1)].to_i(16))
        cooker_status.error = COOKER_ERROR[status_hex[(i+=1)..(i+=1)].to_i(16)]
      end
    end
    cooker_status
  end

  # Cooker for some reason likes to send FF i.e 255 for some values
  def handle_invalid_value(value)
    if (value == 255)
      return 0
    else return value
    end
  end

  def handle_reserve_bytes(temp2_hex)
    result = 0
    if (temp2_hex.casecmp("00") == 0 || temp2_hex.casecmp("0A") == 0 || temp2_hex.casecmp("0E") == 0)
      result = temp2_hex.to_i(16)
    end
    result
  end

  def user_program_command(prog_array)
    user_program_head = Settings.cooker_commands.user_program_head
    args_array = Array.new
    prog_array.each do |prog|
      args_array.push(*get_hex_array(prog.step, prog.hour, prog.minute, prog.temperature))
    end
    user_program_command = user_program_head + args_array.join('')
    get_base64_command(user_program_command, user_program_head, *args_array)
  end

  def parse_stun_response(response)
    result = Array.new
    if (!response.blank?)
      begin
        parsed_response = response[:device_response][:body]
        Rails.logger.info "Parse body: #{parsed_response}"
        # split all the sections
        arr2 = parsed_response.split(",")
        result.push(arr2[0].gsub(/\p{Space}/,'').split(":")[1])
        result.push(arr2[1].gsub(/\p{Space}/,'').split(":")[1])
        Rails.logger.info "result: #{result}"
      rescue Exception => e
        internal_error!(CONNECTION_REFUSED, "Unable to communicate with Cooker. Please try again!")
      end
    end
    if (!result || result[0].blank? || result[0] == "-1")
      internal_error!(CONNECTION_REFUSED, "Unable to communicate with Cooker. Please try again!")
    end
    result
  end

  def parse_cancel_response(status)
    result = Hash.new
    Rails.logger.info "Status from device is: #{status}"
    if (!status.blank?)
      split_response = status.split(';')
      ack_hex = base64_to_hex(split_response[0])
      result["cooker_status"] = parse_status(split_response[1]) unless split_response.length < 2
      if ((Settings.cooker_commands.slave_ack_head.casecmp(ack_hex[4..5]) == 0) && (Settings.cooker_commands.cancel_master_head.casecmp(ack_hex[6..7]) == 0))
        result["result"] = "Cancel command acknowledged by the device!"
      end
    end
    result
  end

  def get_hex_array(*args)
    Rails.logger.info "Array to be changed to hex: #{args}"
    hex_array = Array.new
    args.each do |arg|
      hex = arg.to_s(16).rjust(2, '0')
      if (hex.casecmp(Settings.cooker_commands.packet_head) == 0)
        hex_array.push("70")
        hex_array.push("0e")
      elsif (hex.casecmp(Settings.cooker_commands.reserve_byte) == 0)
        hex_array.push("70")
        hex_array.push("00")
      elsif (hex.casecmp(Settings.cooker_commands.packet_tail) == 0)
        hex_array.push("70")
        hex_array.push("0a")
      else
        hex_array.push(hex)
      end

    end
    hex_array
  end

  def get_empty_user_program()
    user_programs = Array.new
    # There can be a mximum of nine steps in a user defined program
    for i in 0..8
      program = CookerUserProgram.new
      program.step = i + 1
      program.hour = program.minute = program.temperature = 0
      user_programs[i] = program
    end
    user_programs
  end

  # Encode UART binary to base64
  def get_base64_command(command, *args)
    length = (args.length).to_s(16).rjust(2, '0')
    check_code = get_hex_check_code(*args)
    hex_to_base64(length + command + check_code)
  end

  # Get check sum for UART binary command
  def get_hex_check_code(*hex_data)
    sum = 0
    hex_data.each do |hex|
      sum += hex.to_i(16)
    end
    sum.to_s(16).rjust(4, '0')
  end

  def hex_to_base64(input_hex)
    input_hex = Settings.cooker_commands.packet_head + input_hex + Settings.cooker_commands.packet_tail
    Rails.logger.info "hex to be base64 is: #{input_hex}"
    [[input_hex].pack("H*")].pack("m0")
  end

  def base64_to_hex(input_base64)
    input_base64.unpack("m0").first.unpack("H*").first
  end

  def get_other_recipes(query)
    result = Array.new
    uri = Settings.cooker_commands.recipe_api_url % URI::encode(query)
    response = HTTParty.get(uri,:headers => { 'Content-Type' => 'application/json' })
    body = JSON.parse(response.body)

    body["recipes"].each do |recipe|
      Rails.logger.info "body: #{recipe}"
      recipe_third_party = RecipeThirdParty.new
      recipe_third_party.title = recipe["title"]
      recipe_third_party.source_url = recipe["source_url"]
      recipe_third_party.image_url = recipe["image_url"]
      recipe_third_party.recipe_id = recipe["recipe_id"]
      recipe_third_party.recipe_url = recipe["f2f_url"]
      result.push(recipe_third_party)
    end
    result
  end

  # Parses a 3rd party url for recipe info
  def parse_other_url(uri)
    begin
      doc = Nokogiri::HTML(HTTParty.get(uri))
      hour_text = doc.css("#cookHoursSpan").first.text
      secs = ChronicDuration::parse(hour_text, :minutes => true)
      if (secs.blank?)
        bad_request!(INVALID_REQUEST, "Unable tp parse recipe to get cook time.")
      end
      mins = secs > 0 ? secs/60 : 0
      if (mins > 0 && mins > 59)
        hour = mins/60
        mins = mins%60
      else
        hour = 0
        mins = mins
      end
      Rails.logger.info "hour: #{hour} mins: #{mins}"
    rescue URI::InvalidURIError => e
      bad_request!(INVALID_REQUEST, "Invalid input url #{uri}.")
    rescue Exception => e
      internal_error!(IO_ERROR, "Unable to parse recipe from url #{uri}.")
    end
    user_program_array = get_empty_user_program()
    user_program = user_program_array[0]
    user_program.hour = hour
    user_program.minute = mins
    user_program.temperature = Settings.cooker_commands.low_temperature
    user_program_array[0] = user_program
    user_program_array
  end

end
