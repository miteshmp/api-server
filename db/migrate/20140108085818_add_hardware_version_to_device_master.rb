class AddHardwareVersionToDeviceMaster < ActiveRecord::Migration
  def change
    add_column :device_masters, :hardware_version, :string
  end
end
