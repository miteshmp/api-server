class RemoveModelNoFromDeviceMasters < ActiveRecord::Migration
  def up
    remove_column :device_masters, :model_no
  end

  def down
    add_column :device_masters, :model_no, :string
  end
end
