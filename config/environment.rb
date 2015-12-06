# Load the rails application
require File.expand_path('../application', __FILE__)

#ENV['JAVA_HOME'] = "/usr/java/jdk1.5.0_09"
#ENV['LD_LIBRARY_PATH'] = "#{ENV['LD_LIBRARY_PATH']}:#{ENV['JAVA_HOME']}/jre/lib/i386:#{ENV['JAVA_HOME']}/jre/lib/i386/client"

# Initialize the rails application
APIServer::Application.initialize!

ActionMailer::Base.delivery_method = :smtp

ActionMailer::Base.smtp_settings = {
   :address => Settings.address,
   :port => Settings.port,
   :domain => Settings.domain,
   :authentication => :login,
   :user_name => Settings.user_name,
   :password => Settings.password,
   :enable_starttls_auto => true
}
ActionMailer::Base.raise_delivery_errors = true
