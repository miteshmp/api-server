require 'mandrill'
module MandrillHelper

	# Module :- "send_mail"
	# Description :- Sends mail using mandrill-api
	def send_mail(template_name,recepient,global_merge_vars=[],attachments=[])
		mandrill = MandrillWrapper.instance.mandrill
		template_content = []

		message = {  
		 :to=>[  
		   {  
		     :email=> recepient
		   }  
		 ],  
		 :from_email=> Settings.from,
		 :global_merge_vars => global_merge_vars,
		 :attachments => attachments
		}  
		retry_limit = Settings.email_retry_limit
		begin
			sending = mandrill.messages.send_template template_name,template_content,message
		rescue Timeout::Error,Errno::ETIMEDOUT,Errno::ECONNREFUSED,Excon::Errors::SocketError
			retry_limit -=1
			retry if retry_limit > 0
		rescue Exception => e
			Thread.new{
				ExceptionNotifier.notify_exception(e).deliver
			}
		end
	end

	# Module :- "send_mail"
	# Description :- Sends mail using mandrill-api
	def send_mail_with_subject(subject,template_name,recepient,global_merge_vars=[],attachments=[])
		mandrill = MandrillWrapper.instance.mandrill
		template_content = []

		message = {
		 :subject => subject,	  
		 :to=>[  
		   {  
		     :email=> recepient
		   }  
		 ],  
		 :from_email=> Settings.from,
		 :global_merge_vars => global_merge_vars,
		 :attachments => attachments
		}  
		retry_limit = Settings.email_retry_limit
		begin
			sending = mandrill.messages.send_template template_name,template_content,message
		rescue Timeout::Error,Errno::ETIMEDOUT,Errno::ECONNREFUSED,Excon::Errors::SocketError
			retry_limit -=1
			retry if retry_limit > 0
		rescue Exception => e
			Thread.new{
				ExceptionNotifier.notify_exception(e).deliver
			}
		end
	end	

	# Action :- send_welcome_mail
  	# Parameter :- recepient :- Receiver mail id
  	#              username :- Username
	def send_welcome_mail(recepient,username)
	 template_name = "Welcome Email"
	 global_merge_vars = [		            
		            {
		                "name" => "USER_NAME",
		                "content" => username
		            }
		        ]
	
	 send_mail(template_name,recepient,global_merge_vars)
	end	

	# Action :- send_device_share_invitation
  	# Parameter :- owner :- Device owner mail id
  	#              recepient :- Receiver mail id
  	# 			   invitation_key :- Invitation key
	def send_device_share_invitation(owner,recepient,invitation_key)
		template_name = "Device Share"
		global_merge_vars = [		            
		            {
		                "name" => "OWNER",
		                "content" => owner
		            },
		            {
		            	"name" => "DEVICE_SHARE_URL",
		                "content" => Settings.device_share_url+invitation_key
		            }
		        ]

		send_mail(template_name,recepient,global_merge_vars)    

	end

	# Action :- send_batch_location_convert_report
  	# Parameter :- name :- File name
  	#              path :- File path
	def send_batch_location_convert_report(name,path)
		template_name = "Batch Location Convert Report"
		attachments = [
		 	{
		 		:type => "text/plain",
		 		:name => name,
		 		:content => Base64.encode64(File.read(path))
		 	}
		 ]
		recepient = Settings.exception_notifier.recepient
		send_mail(template_name,recepient,nil,attachments)
	end	

	# Action :- send_recurly_exception_mail
  	# Parameter :- recurly_token :- Recurly token
  	#              Error :- Reason for recurly exception
	def send_recurly_exception_mail(recurly_token,error)
		template_name = "Recurly Exception"
		recepient = Settings.exception_notifier.recepient
		global_merge_vars = [		            
		            {
		                "name" => "RECURLY_TOKEN",
		                "content" => recurly_token
		            },
		            {
		            	"name" => "ERROR",
		                "content" => error
		            }
		        ]

		send_mail(template_name,recepient,global_merge_vars)    
	end	

	# Action :- send_s3_folder_cleanup_report
  	# Parameter :- data :- Data contains device registration ids and corresponding deleted clips and snaps count.
	def send_s3_folder_cleanup_report(data)
		template_name = "Report"
		recepient = Settings.exception_notifier.recepient
		global_merge_vars = [		            
		            {
		                "name" => "DATA",
		                "content" => data
		            }
		        ]

		send_mail(template_name,recepient,global_merge_vars)    	
	end	


  	# Action :- send_hubble_device_issue_mail
  	# Parameter :- device :- Device Object
  	#              id :- Device Issue ID
  	#              type :- Device issue type
  	#              reason :- issue reason if any
	def send_hubble_device_issue_mail(device,id,type,reason="N/A",response_code="N/A",url="N/A")
		template_name = "Device issue mail"
		recepient = Settings.exception_notifier.recepient
		remote_ip = device.device_location ? device.device_location.remote_ip : nil
		global_merge_vars = [		            
		            {
		                "name" => "ID",
		                "content" => id
		            },
		            {
		                "name" => "TYPE",
		                "content" => type
		            },
		            {
		                "name" => "REASON",
		                "content" => reason
		            },
		            {
		                "name" => "REGISTRATION_ID",
		                "content" => device.registration_id
		            },
		            {
		                "name" => "FIRMWARE_VERSION",
		                "content" => device.firmware_version
		            },
		            {
		                "name" => "USER_ID",
		                "content" => device.user_id
		            },
		            {
		                "name" => "REMOTE_IP",
		                "content" => remote_ip
		            },
		            {
		                "name" => "RESPONSE_CODE",
		                "content" => response_code
		            },
		            {
		                "name" => "ENV_URL",
		                "content" => url
		            },
		            {
		                "name" => "ENVIRONMENT",
		                "content" => Rails.env
		            },
		        ]

		send_mail(template_name,recepient,global_merge_vars)    	
	end

	# Action :- send_free_trial_mail
	def send_free_trial_mail(recepient,device_name,username)
		template_name = "Hubble Platform Trial Available"
		global_merge_vars = [		            
		            {
		                "name" => "DEVICE_NAME",
		                "content" => device_name
		            },
		            {
		                "name" => "USER_NAME",
		                "content" => username
		            }	           
		        ]

		send_mail(template_name,recepient,global_merge_vars)    	
	end

	# Action :- send_free_trial_expiring_mail
	def send_free_trial_expiring_mail(recepient,device_name,username)
		template_name = "Hubble Platform 3 Day Warning"
		global_merge_vars = [		            
		            {
		                "name" => "DEVICE_NAME",
		                "content" => device_name
		            },
		            {
		                "name" => "USER_NAME",
		                "content" => username
		            }		           
		        ]

		send_mail(template_name,recepient,global_merge_vars)    	
	end

	# Action :- send_free_trial_expired_mail
	def send_free_trial_expired_mail(recepient,device_name,username)
		template_name = "Hubble Platform Trial is Over"
		global_merge_vars = [		            
		            {
		                "name" => "DEVICE_NAME",
		                "content" => device_name
		            },
		            {
		                "name" => "USER_NAME",
		                "content" => username
		            }		           
		        ]

		send_mail(template_name,recepient,global_merge_vars)    	
	end

		# Action :- send_free_trial_expired_mail
	def send_generic_mail(subject, data)
		template_name = "Generic Mail"
		recepient = Settings.exception_notifier.recepient
		global_merge_vars = [		            
		            {
		                "name" => "DATA",
		                "content" => data
		            }		           
		        ]

		send_mail_with_subject(subject,template_name,recepient,global_merge_vars)	
	end	
end
