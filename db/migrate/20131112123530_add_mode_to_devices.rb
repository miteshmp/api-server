class AddModeToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :mode, :integer
  end
end
