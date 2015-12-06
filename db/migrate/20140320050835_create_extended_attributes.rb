class CreateExtendedAttributes < ActiveRecord::Migration
  def change
    create_table :extended_attributes do |t|
      t.string :entity_type
      t.integer :entity_id
      t.string :key
      t.text :value

      t.timestamps
    end
  end
end
