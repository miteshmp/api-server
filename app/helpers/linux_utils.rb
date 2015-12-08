class Linux_utils
	def self.put_memory_info_to_cloudwatch
	 perl_file_path = Rails.root.join("aws-scripts-mon","mon-put-instance-data.pl").to_s 
	 iam_role = Settings.iam_role
	 exe_command = perl_file_path+'   --mem-util --auto-scaling=only  --aws-iam-role='+iam_role+'  --mem-used-incl-cache-buff  --from-cron
'
	 system(exe_command)
	end
end

