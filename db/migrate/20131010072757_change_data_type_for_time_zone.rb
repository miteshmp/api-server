class ChangeDataTypeForTimeZone < ActiveRecord::Migration
  def up
  	change_table :devices do |t|
      t.change :time_zone, :float
    end
  end

  def down
  	change_table :devices do |t|
      t.change :time_zone, :string
    end
  end
end
