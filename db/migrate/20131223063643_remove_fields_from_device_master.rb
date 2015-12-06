class RemoveFieldsFromDeviceMaster < ActiveRecord::Migration
  def up
    remove_column :device_masters, :report
    remove_column :device_masters, :hardware_version
  end

  def down
    add_column :device_masters, :hardware_version, :string
    add_column :device_masters, :report, :string
  end
end
