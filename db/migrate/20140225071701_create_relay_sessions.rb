class CreateRelaySessions < ActiveRecord::Migration
  def change
    create_table :relay_sessions do |t|
      t.string :registration_id
      t.string :session_key
      t.string :stream_id

      t.timestamps
    end
    add_index :relay_sessions, :registration_id, :unique => true
    add_index :relay_sessions, [:session_key, :stream_id], :unique => true
  end
end
