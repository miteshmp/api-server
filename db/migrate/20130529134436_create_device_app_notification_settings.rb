class CreateDeviceAppNotificationSettings < ActiveRecord::Migration
  def change
    create_table :device_app_notification_settings do |t|
      t.references :app
      t.references :device
      t.integer :alert
      t.boolean :is_enabled

      t.timestamps
    end
    add_index :device_app_notification_settings, :app_id
    add_index :device_app_notification_settings, :device_id
  end
end
