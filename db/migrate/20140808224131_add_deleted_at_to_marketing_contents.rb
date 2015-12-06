class AddDeletedAtToMarketingContents < ActiveRecord::Migration
  def change
    add_column :marketing_contents, :deleted_at, :time
  end
end
