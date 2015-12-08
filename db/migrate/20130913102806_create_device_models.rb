class CreateDeviceModels < ActiveRecord::Migration
  def change
    create_table :device_models do |t|
      #t.string :id
      t.string :code
      t.string :name
      t.string :description
	  t.text :capability
      t.references :device_type

      t.timestamps
    end
  end
end
