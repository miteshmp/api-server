class AddDeletedAtToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :deleted_at, :datetime
  end
end
