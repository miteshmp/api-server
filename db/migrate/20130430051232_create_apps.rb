class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.integer :id
      t.string :name
      t.string :device_code
      t.string :type
      t.integer :notification_type
      t.string :registration_id
      t.string :sns_endpoint
      t.string :software_version
      t.references :user
      t.timestamps
    end
    add_index :apps, :device_code, :unique => true
  end
end
