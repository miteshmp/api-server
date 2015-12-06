class ChangeDeletedAtTypeInDeviceTypes < ActiveRecord::Migration
  def up
  	change_table :device_types do |t|
      t.change :deleted_at, :datetime
    end
  end

  def down
  	ef up
  	change_table :device_types do |t|
      t.change :deleted_at, :time
    end
  end
end
