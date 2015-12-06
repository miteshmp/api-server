class AddRouterDetailsToDevices < ActiveRecord::Migration
  def change
	add_column :devices, :host_ssid, :string,:default => nil
	add_column :devices, :host_router, :string,:default => nil
  end
end
