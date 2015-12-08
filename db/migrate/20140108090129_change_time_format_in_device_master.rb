class ChangeTimeFormatInDeviceMaster < ActiveRecord::Migration
  def up
  	change_table :device_masters do |t|
      t.change :time, :datetime
    end
  end

  def down
  	change_table :device_masters do |t|
      t.change :time, :string
    end
  end
end
