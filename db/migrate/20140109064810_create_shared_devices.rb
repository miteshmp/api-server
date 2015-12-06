class CreateSharedDevices < ActiveRecord::Migration
  def change
    create_table :shared_devices do |t|
      t.integer :shared_by
      t.integer :shared_with
      t.references :device

      t.timestamps
    end
  end
end
