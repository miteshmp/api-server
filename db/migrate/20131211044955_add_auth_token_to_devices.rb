class AddAuthTokenToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :auth_token, :string
  end
end
