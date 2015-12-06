class GeneralSettings < RailsSettings::CachedSettings
	attr_accessible :var
	defaults[:wowza_ip_mappings] = {'54.255.136.101' => 'dev-w1.hubble.in','106.51.229.162'=>'connect-w1.hubble'}
	defaults[:binatone_model] = '0066'
  defaults[:connect_settings] = {
                                 :tenant_id => ['3'],
                                 :model => ['0166'],
                                 :rtmp_loadbalancer_ip=>'connect-wowza.hubble.in',
                                 :rtmps_ip_list=>['connect-w1.hubble'=>'106.51.229.162','connect-w2.hubble'=>'106.51.229.162'],
                                 :rtmp_loadbalancer_port=>'1935',
                                 :events_get_url_prefix=>'https://connect-file.hubble.in/',
                                 :storage_root_folder=>'/mnt/hubble-resources/',
                                 :default_device_plan=>'connect-tier-1',
                                 :file_server_host=>'connect-file.hubble.in',
                                 :upload_server_event_data_url=>'http://connect-upload.hubble.in:80/v1/uploads/event_data',
                                 :upload_api_token=>'u1VcTCpqhMh_cxtRSKQL',
                                 :s3_device_image_path_1=> "http://connect-file.hubble.in:8080/devices/"
                                }
  end