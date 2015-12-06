class AddAppUniqueIdToApps < ActiveRecord::Migration
  def change
    add_column :apps, :app_unique_id, :string

    # Fill the app_unique_ids for existing apps
    default_gcm_app_unique_id = "default_gcm"
    default_apns_app_unique_id = "default_apns"
    
    App.update_all({app_unique_id: default_gcm_app_unique_id},{notification_type: 1})
    App.update_all({app_unique_id: default_apns_app_unique_id},{notification_type: 2})
  end
end
