class Notifier < ActionMailer::Base


default :from => Settings.from

  def welcome(recipient)
    @recipient = recipient
    mail(:to => recipient,
         :subject => "Welcome to monitoreverywhere.com"
        )
    
  end
  
 
  def forgot_password(recipient,encrypted_guid)
    @recipient = recipient
    @encrypted_guid = encrypted_guid
    mail(:to => recipient,
         :subject => "Forgot password?"
        )
       
  end

  def batch_location_convert_report(name,path)
    recipient = Settings.exception_notifier.recepient
    attachments[name] = File.read(path)
    mail(:to => recipient,
         :subject => "Batch location convert report"
        )
  end 

  def recurly_exception(recurly_token,error)
    recipient = Settings.exception_notifier.recepient
    @recurly_token = recurly_token
    @error = error
    mail(:to => recipient,
         :subject => "Recurly Exception"
        )
  end 

  def recurly_subscription(recurly_token)
    recipient = Settings.exception_notifier.recepient
    @recurly_token = recurly_token
    mail(:to => recipient,
         :subject => "Recurly token invalid"
        )
  end 

  def test(subject,account,data)
    recipient = "kavya.vj@connovatech.com"
    @data = data
    @account = account
    mail(:to => recipient,
         :subject => subject
        )
  end 

  def notification_test(subject,data)
    recipient = Settings.exception_notifier.recepient
    @data = data
    mail(:to => recipient,
         :subject => subject
        )
  end 

  def settings_exception(data)
    @data = data
    mail(:to => Settings.exception_notifier.recepient,
         :subject => "Settings exception"
        )
  end 


  def ecommerce_mail(recipient,subject,data)
    @data = data
    mail(:to => recepient,
         :subject => subject
        )
  end 


  def device_share(owner,recipient,invitation_key)
    @owner = owner
    @invitation_key = invitation_key
    @recipient = recipient
    mail(:to => recipient,
         :subject =>  "Monitore Everywhere : You are invited to share device"
        )
  end 

  def device_share_reminder(owner,recipient,invitation_key)
    @owner = owner
    @invitation_key = invitation_key
    @recipient = recipient
    mail(:to => recipient,
         :subject =>  "Monitore Everywhere : You are invited to share device"
        )
  end  

  def send_email(data,subject)    
    @recipient = Settings.exception_notifier.recepient
    @data = data
    mail(:to => @recipient,
         :subject => subject
        )
  end



end
