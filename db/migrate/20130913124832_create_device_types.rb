class CreateDeviceTypes < ActiveRecord::Migration
  def change
    create_table :device_types do |t|
      #t.string :id
      t.string :code
      t.string :name
      t.string :description
      t.text :capability

      t.timestamps
    end
  end
end
