include MandrillHelper
class EventsCleaner

  def self.remove_db_events(expiry_period)
    count = DeviceEvent.where("time_stamp < '#{expiry_period.days.ago}' AND deleted_at is null").count
    # Updating too many records may lead to slow db performance
    # We go the old fashioned slow route if the count exceeds a specific threshold
    # TODO: Determine the optimum amount of records that can be updated below
    Rails.logger.info "count: #{count}"
    if (count > 100000)
      limit = 5000
      offset = 0
      while ((offset + limit) <= count) do
        DeviceEvent.transaction do
          # MySql doesn't allow limits inside a subquery and hence we wrap it another select statement
          DeviceEvent.update_all("deleted_at = '#{Time.now}'", 
            "id in (select id from (select id from #{DeviceEvent.table_name} where time_stamp < '#{expiry_period.days.ago}'  and (storage_mode =0 or storage_mode is null) limit #{offset}, #{limit}) t)")
        end
        offset += limit 
      end
    # We go the fast route here
    elsif (count > 0)
      DeviceEvent.transaction do
        DeviceEvent.update_all("deleted_at = '#{Time.now}'", "time_stamp < '#{expiry_period.days.ago}' and (storage_mode =0 or storage_mode is null)")
      end
    end
    return count
  end

  # We only remove database objects that are older than highest data_retention period.
  # S3 objects will be removed through a dedicated background job/object expiry mechanism.
  def self.remove_objects
    highest_data_retention_days = 31
    plan_days = PlanParameter.where(parameter: PLAN_PARAMETER_DATA_RETENTION_FIELD).maximum(:value)
    if (!plan_days.blank?)
      highest_data_retention_days = plan_days.to_i
    end
    # We add a buffer of one day to avoid edge case deletion
    records_deleted = remove_db_events(highest_data_retention_days + 1)
    Rails.logger.info "Deleted #{records_deleted} device_events records at #{Time.now}"
    send_generic_mail("Background cleaner run for #{Time.now}", "Deleted #{records_deleted} device_events records!")
  end

end
