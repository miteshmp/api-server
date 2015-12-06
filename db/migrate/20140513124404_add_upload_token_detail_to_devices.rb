class AddUploadTokenDetailToDevices < ActiveRecord::Migration
  def change
  	add_column :devices, :upload_token, :string,:default => nil
	add_column :devices, :upload_token_expires_at, :string,:default => nil
  end
end
