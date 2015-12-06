class AddStreamNameToDevices < ActiveRecord::Migration
  
  def change
  
  	add_column :devices,  :stream_name, :string
  	add_column :devices,  :derived_key, :string
  	add_index  :devices,  :stream_name
  
  end

end
