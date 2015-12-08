class FixTypeCode < ActiveRecord::Migration
  def change
    rename_column :device_types, :code, :type_code
  end
end
