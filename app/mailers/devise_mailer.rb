include MandrillHelper
class DeviseMailer < Devise::Mailer
  def reset_password_instructions(record,token,opts={})
    template_name = "Hubble Forgot Password Email"
    recepient = record.email  
    reset_password_url=nil
    case record.tenant_id.to_s
      when *GeneralSettings.connect_settings[:tenant_id] #for connect camera
        reset_password_url="#{GeneralSettings.connect_settings[:reset_password_connect_portal_url]}#resetpassword"
      else #for normal hubble cameras
        reset_password_url=Settings.reset_password_portal_url
      end
    global_merge_vars = [                
              {
                  "name" => "RESET_PASSWORD_URL",
                  "content" => "#{reset_password_url}/#{token}"
              },
              {
                  "name" => "USER_NAME",
                  "content" => record.name
              }
          ]  
    send_mail(template_name,recepient,global_merge_vars) 
  end
end