AWS.config({
		:access_key_id => Settings.aws_access_key_id,
		:secret_access_key => Settings.aws_secret_access_key,
})

AWS.config(:max_retries => Settings.aws_max_retries)