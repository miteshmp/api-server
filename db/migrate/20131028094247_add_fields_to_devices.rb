class AddFieldsToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :last_accessed_date, :datetime
    add_column :devices, :deactivate, :boolean,:default => false
    add_column :devices, :target_deactivate_date, :datetime
  end
end
