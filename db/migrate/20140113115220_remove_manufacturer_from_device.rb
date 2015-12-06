class RemoveManufacturerFromDevice < ActiveRecord::Migration
  def up
    remove_column :devices, :manufacturer
  end

  def down
    add_column :devices, :manufacturer, :string
  end
end
