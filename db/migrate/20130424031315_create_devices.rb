class CreateDevices < ActiveRecord::Migration
  def change
    create_table :devices do |t|
      t.string :name
      t.string :registration_id
	  t.string :master_key
      t.string :access_token
      t.string :manufacturer
      t.string :time_zone
      t.string :subscription_type,                   :default => "freemium"
      t.references :device_model 
      t.references :user 

      t.timestamps
    end
    add_index :devices, :registration_id, :unique => true
    add_index :devices, :master_key, :unique => true
    add_index :devices, :device_model_id    
  end
end
