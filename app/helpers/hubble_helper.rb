# This module defines different module for Hubble system.

module HubbleHelper

	# Module :- get_LoadBalancer_regionCode
	# Description :- It returns region code based on ISO-3166
	def get_LoadBalancer_regionCode(isoCode)

		regionCode = HubbleConfiguration::DEFAULT_REGION_CODE;

		if isoCode != nil
        	
        	RegionIsoCode::REGION_CODE.each do |key, value|

          		if Array.wrap(key).include? isoCode
          			regionCode = value ;
            		break;
          		end

        	end
        end

        return regionCode;
	end
	# Complete :- "get_LoadBalancer_regionCode"

	# Module :- get_country_ISOCode
	# Description :- It returns ISO code based on remote IP address
	def get_country_ISOCode(remote_ip_address)

        dataBase = MaxMindDB.new(Rails.root.join('./lib/assets/GeoLite2-Country.mmdb'))

        if remote_ip_address != nil
        	
        	ret = dataBase.lookup(remote_ip_address)

        	if ret.found? # => true
      			return ret.country.iso_code
      		end

      	end
      	return nil;
	end
	# Complete :- "get_country_ISOCode"

  # Module :- get_device_status
  # Description :- It should return device status

  def get_device_status(registration_id,active_user)

    device_status  = DeviceStatus::NOT_FOUND_IN_DEVICE_MASTER ;

    # Get Device Addres from device registration ID
    device_mac_address = registration_id[6..17] ;

    # First check that device is already present in Device Master or not.
    device_master = DeviceMaster.select("id,registration_id").where(registration_id: registration_id, mac_address: device_mac_address).first

    if device_master

      # Device is present in device master.
      device = Device.with_deleted.where(registration_id: registration_id).first

      if device

        # Check that device is registered with current user or not.
        # Device is not deleted from current user account
        if  ( device.user_id  == active_user.id && device.deleted_at == nil)

          # Device is registered with current User.
          device_status = DeviceStatus::REGISTERED_CURRENT_USER;

        elsif  ( device.user_id  != active_user.id && device.deleted_at == nil)

          # Device is registered with other account & device is not deleted from that account.
          # Application can not register this device.
          # device_status = DeviceStatus::REGISTERED_OTHER_USER ;
          # allow to register device which is registered with other account
          device_status = DeviceStatus::DELETED_DEVICE;

        elsif ( device.deleted_at  != nil)

          # Device is deleted previously, so it is ready for registration.
          device_status = DeviceStatus::DELETED_DEVICE ;
        
        else

          # Unknown device status
          device_status = DeviceStatus::UNKNOWN_STATUS;

        end

      else

        # Device is not registered yet any time.
        device_status = DeviceStatus::NOT_REGISTERED_DEVICE ;

      end

    else

      # Device is not present in device master.
      device_status = DeviceStatus::NOT_FOUND_IN_DEVICE_MASTER;

    end

    return device_status;

  end

end