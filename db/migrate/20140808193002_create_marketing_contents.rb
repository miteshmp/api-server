class CreateMarketingContents < ActiveRecord::Migration
  def change
    create_table :marketing_contents do |t|
      t.string :key
      t.text :value

      t.timestamps
    end
  end
end
