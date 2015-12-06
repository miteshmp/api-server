
module ReportsHelper

  def create_user_report()
    report_data = Array.new
    begin
      total_users = User.count
      users_month = User.where("created_at > ? AND created_at < ?", Time.now.beginning_of_month, Time.now.end_of_month).count
      total_devices = Device.count
      devices_month = Device.where("created_at > ? AND created_at < ?", Time.now.beginning_of_month, Time.now.end_of_month).count
      report_data.push({'name' => 'Total Hubble users', 'count' => total_users})
      report_data.push({'name' => 'Total users registered this month', 'count' => users_month})
      report_data.push({'name' => 'Total devices registered with Hubble', 'count' => total_devices})
      report_data.push({'name' => 'Total devices registered this month', 'count' => devices_month})
      # The following query needs refining
      device_query = Device.find_by_sql("select device_count, count(t1.user_id) as user_count from (select user_id, count(id) as device_count from devices where deleted_at is null group by user_id having count(id) >= 1) t1 group by t1.device_count")
      more_device_count = 0
      device_query.each_with_index do |row, index|
        if (row.device_count > 2)
          more_device_count += row.user_count
          if (index == device_query.size-1)
            report_data.push({'name' => "Total users with more than 2 devices", 'count' => more_device_count})
          end
        else
          property = "Total users with #{row.device_count} device"
          report_data.push({'name' => property, 'count' => row.user_count})
        end
      end
    rescue Exception => exception
    ensure
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connection ;
      ActiveRecord::Base.clear_active_connections! ;
    end
    report_data
  end
end
