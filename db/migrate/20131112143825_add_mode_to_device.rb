class AddModeToDevice < ActiveRecord::Migration
  def change
    add_column :devices, :mode, :integer, :default => "1"
  end
end
