class AddAuthTokenIndexToDevices < ActiveRecord::Migration
  def change
    add_index :devices, :auth_token, :unique => true
  end
end
