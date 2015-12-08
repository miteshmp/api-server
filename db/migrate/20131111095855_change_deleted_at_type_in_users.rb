class ChangeDeletedAtTypeInUsers < ActiveRecord::Migration
  def up
  	change_table :users do |t|
      t.change :deleted_at, :datetime
    end
  end

  def down
  	change_table :users do |t|
      t.change :deleted_at, :datetime
    end
  end
end
