class AddFreetrialNotifiedAtToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :freetrial_notified_at, :timestamp
    add_index :devices, :freetrial_notified_at
  end
end
