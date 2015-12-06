  # require 'rjb'
  require 'grape'
  require 'csv-mapper'
  include CsvMapper
  
#file reponse should not be SuccessFormatter but is text/csv

class UploadAPI_v1 < Grape::API

	version 'v1', :using => :path,  :format => :json
	format :json
    formatter :json, SuccessFormatter
	#content_type :txt, "text/csv"
    helpers AwsHelper
    helpers MandrillHelper

	resource :uploads do

    desc "convert the IP Addresses of all cameras into locations (Device authentication required)."

    params do
        requires :file,:desc => "CSV File "
    end

    post 'batch_location_convert' do
        
        bad_request!(INVALID_FILE, "Invalid file") unless params[:file].respond_to?("filename")			
        
        name =  params[:file].filename
        directory = Settings.location_directory
        FileUtils.mkdir_p directory unless File.exist?(directory)

        Thread.new {

            begin
                # create the file path
                path = File.join(directory, name)

                File.open(path, "w+") { |f| f.write(params[:file].tempfile.read) }

                results = import(path) do
                    start_at_row 1
                    [
                        camera_id,
                        mac_address,
                        camera_ip,
                        registration_date,
                        ip_updated_date,
                        stream_mode,
                        symmetric_nat_status,
                        codec,
                        firmware_version
                    ]
                end

                CSV.open(path, "wb") do |csv|

                    i = 0
                    total = results.length

                    csv <<  [
                        "camera_id",
                        "mac_address",
                        "camera_ip",
                        "registration_date",
                        "ip_updated_date",
                        "stream_mode",
                        "symmetric_nat_status",
                        "codec",
                        "firmware_version",
                        "country_code",
                        "country_name",
                        "region_code",
                        "region_name",
                        "city",
                        "zipcode",
                        "latitude",
                        "longitude",
                        "metro_code",
                        "areacode"
                    ]


                    results.each do |camera|

                        i += 1
                        location_info = Geocoder.search(camera.camera_ip)

                        obj = Hash.new

                        if location_info
                            if location_info[0]
                                if location_info[0].data
                                    obj = location_info[0].data
                                end
                            end
                        end

                        csv <<  [
                            camera.camera_id,
                            camera.mac_address,
                            camera.camera_ip,
                            camera.registration_date,
                            camera.ip_updated_date,
                            camera.stream_mode,
                            camera.symmetric_nat_status,
                            camera.codec,
                            camera.firmware_version,
                            obj["country_name"],
                            obj["region_name"],
                            obj["city"],
                            obj["zipcode"],
                            obj["latitude"],
                            obj["longitude"]
                        ]

                    end
                end

                rescue Exception => exception
                ensure
                    ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
                    ActiveRecord::Base.clear_active_connections! ;
            end

            send_batch_location_convert_report(name,path)
            FileUtils.rm_rf(path)
        }
        
        status 200
        "Batch location convert report will be sent to mail"
    	# csv file download
    	# data = File.open(path).read
    	# content_type "text/csv"
    	# body data

    end
    # "batch_location_convert" completed
    end

end
