class CreateRegistrationDetails < ActiveRecord::Migration
  
  def change

  	create_table :registration_details do |t|

  		t.string :registration_id
  		t.string :mac_address
  		t.string :local_ip
  		t.string :net_mask
  		t.string :gateway
  		t.string :remote_ip
  		t.string :expire_at

  		t.timestamps

  	end
  
  	add_index :registration_details, :registration_id, :unique => true
  	add_index :registration_details, :mac_address, :unique => true
  end

end
