class AddUploadTokenToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :upload_token, :string,:default => nil
	add_column :users, :upload_token_expires_at, :string,:default => nil
  end
end
