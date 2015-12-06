class AddIndexToApps < ActiveRecord::Migration
  def change
  	add_index :apps, :user_id
  end
end
