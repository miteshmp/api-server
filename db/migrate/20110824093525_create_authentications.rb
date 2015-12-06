class CreateAuthentications < ActiveRecord::Migration
  def self.up
    create_table :authentications do |t|
      t.references :resource, :polymorphic => true
      t.integer :user_id
      t.string :provider
      t.string :uid
      t.string :uname
      t.string :uemail
      t.string :secret
      t.string :link
      t.string :name
      t.string :code
      t.string :access_token
      t.string :refresh_token
      t.time :access_token_expires_at
      
      t.timestamps
    end
  end

  def self.down
    drop_table :authentications
  end
end
