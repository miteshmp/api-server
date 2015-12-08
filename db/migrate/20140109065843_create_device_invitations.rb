class CreateDeviceInvitations < ActiveRecord::Migration
  def change
    create_table :device_invitations do |t|
      t.integer :shared_by
      t.string :shared_with
      t.string :invitation_key
      t.integer :reminder_count,:default => 0
      t.references :device

      t.timestamps
    end
  end
end
