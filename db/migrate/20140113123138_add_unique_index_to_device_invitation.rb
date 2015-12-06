class AddUniqueIndexToDeviceInvitation < ActiveRecord::Migration
  def change
  	add_index :device_invitations, [:shared_by, :shared_with, :device_id],:unique => true, :name => "invitation"
  end
end
