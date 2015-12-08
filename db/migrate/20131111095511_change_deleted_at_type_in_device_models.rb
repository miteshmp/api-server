class ChangeDeletedAtTypeInDeviceModels < ActiveRecord::Migration
  def up
  	change_table :device_models do |t|
      t.change :deleted_at, :datetime
    end
  end

  def down
  	change_table :device_models do |t|
      t.change :deleted_at, :datetime
    end
  end
end
