# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

 	user = User.where(name: "admin").first
   unless user  
   	  user = User.new	 
      user.name = "admin"
      user.email = "me.notifications@monitoreverywhere.com"
      user.password = "2h>um29jBWt7"
      user.password_confirmation = "2h>um29jBWt7"
      user.roles_mask = 1
      user.save!
      user.reset_authentication_token!
  end    
