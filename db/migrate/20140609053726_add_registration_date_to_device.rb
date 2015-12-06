class AddRegistrationDateToDevice < ActiveRecord::Migration
  def change
  	add_column :devices, :registration_at, :datetime,:default => nil
  end
end
