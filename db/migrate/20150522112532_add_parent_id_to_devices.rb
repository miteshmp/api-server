class AddParentIdToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :parent_id, :string
  end
end
