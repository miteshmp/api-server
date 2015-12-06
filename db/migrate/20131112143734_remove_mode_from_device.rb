class RemoveModeFromDevice < ActiveRecord::Migration
  def up
    remove_column :devices, :mode
  end

  def down
    add_column :devices, :mode, :integer
  end
end
