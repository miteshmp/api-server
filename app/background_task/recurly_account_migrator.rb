include RecurlyHelper
class RecurlyAccountMigrator

	def self.migrate_accounts
		start = Time.now
		# Select batch of users at a time to migrate
		User.select("id, email, name").find_each(batch_size: 500) do |user|
			RecurlyHelper.create_recurly_account(user)
		end
		Rails.logger.info "Completed recurly account migration in #{(Time.now - start)}s"
	end
end
