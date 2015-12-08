module RecurlyHelper
	def create_recurly_account(user)
		account = Recurly::Account.create(
		  :account_code => user.id,
		  :email        => user.email,
		  :first_name   => user.name		
		)
	end	

	def create_recurly_device_account(device)
		account = Recurly::Account.create(
		  :account_code => device.registration_id
		)
	end	

	def delete_recurly_account(user)
		account = Recurly::Account.find(user.id)
		account.destroy
	end

	def list_accounts
		list = []		
		Recurly::Account.find_each do |account|
			list << account
		end
		list
	end

	def get_account(id)
		begin
  			account = Recurly::Account.find id  		 	
  			#puts "Account: #{account.inspect}"
		rescue Recurly::Resource::NotFound => e
  			puts e.message
		end
		account
	end	

	def list_coupons
		coupons = []		
		Recurly::Coupon.find_each do |coupon|
  			coupons << coupon
		end
		coupons
	end

	def deactivate_coupon(coupon_code)
		begin
			coupon = Recurly::Coupon.find(coupon_code)
			coupon.destroy
		rescue Recurly::Resource::NotFound => e
  			e.message
		end
	end

	def create_coupon(coupon_code,name,discount_type) 
		coupon = Recurly::Coupon.new(
		  :coupon_code    => coupon_code,
		  :redeem_by_date => Date.new(2014, 1, 1),
		  :single_use     => true
		)

		if(discount_type == 'dollars')
			# $2 off...
			coupon.name = name
			coupon.discount_type = 'dollars'
			coupon.discount_in_cents = 2_00
		else
			# ...or 10% off.
			coupon.name = name
			coupon.discount_type = 'percent'
			coupon.discount_percent = 10
		end	

		# Limit to gold and platinum plans only.
		coupon.applies_to_all_plans = false
		coupon.plan_codes = %w(sample)

		coupon.save
		coupon

	end 

	def lookup_coupon(coupon_code)
		begin
			coupon = Recurly::Coupon.find(coupon_code)
		rescue Recurly::Resource::NotFound => e
			e.message
		end			
	end	

	def create_plan(plan_code,name,unit_amount_in_cents)
		plan = Recurly::Plan.create(
		  :plan_code            => plan_code,
		  :name                 => name,
		  :unit_amount_in_cents => { 'USD' => 10_00, 'EUR' => 8_00 },
		  :setup_fee_in_cents   => { 'USD' => 60_00, 'EUR' => 45_00 },
		  :plan_interval_length => 1,
		  :plan_interval_unit   => 'months'
		)


	end	

	def list_plans
		plans = []
		Recurly::Plan.find_each do |plan|
 			#puts "Plan: #{plan.inspect}"
 			plans << plan
		end
		plans
	end

	def list_add_ons(plan_code) 
		plan = Recurly::Plan.find(plan_code)
		add_ons = []
		plan.add_ons.find_each do |add_on|
			add_ons << add_on
		  #puts "Add-on: #{add_on.inspect}"
		end
		add_ons
	end 

	def create_add_on(plan_code,add_on_code,name)
		plan = Recurly::Plan.find(plan_code)
		add_on = plan.add_ons.create(
		  :add_on_code          => add_on_code,
		  :name                 => name,
		  :unit_amount_in_cents => 2_00
		)
	end	

	def update_add_on(plan_code,add_on_code)
		plan = Recurly::Plan.find(plan_code)
		add_on = plan.add_ons.find(add_on_code)
		add_on.update_attributes :unit_amount_in_cents => 90_00

	end

	def delete_add_on(plan_code,add_on_code)
		plan = Recurly::Plan.find(plan_code)
		add_on = plan.add_ons.find(add_on_code)
		add_on.destroy

	end	

	def list_subscriptions
		subscriptions = []
		Recurly::Subscription.find_each do |subscription|
			subscriptions << subscription
		  #puts "Susbcription: #{subscription}"
		end
		subscriptions
	end	

	def list_account_subscriptions(account_code)
		account = Recurly::Account.find(account_code)
		subscriptions = []
		account.subscriptions.find_each do |subscription|
		  #puts "Subscription: #{subscription.inspect}"
		  subscriptions << subscription
		end
		subscriptions
	end	

	def list_subscription_details(uuid)
		subscription = Recurly::Subscription.find(uuid)
	end	

	def get_subscription_details(uuid)
		subscription = Recurly::Subscription.find(uuid)
		account_code,plan_code = subscription.account.account_code, subscription.plan.plan_code
	end


	def create_subscription(plan_code,account_code)
		# todo : account => nested atrributes
		subscription = Recurly::Subscription.create(
		  :plan_code => plan_code,
		  :account   => {
		    :account_code => account_code
		    
		  }
		)
				
	end	

	def update_subscription(uuid,plan_code)
		subscription = Recurly::Subscription.find(uuid)
		subscription.update_attributes(
		  :plan_code => plan_code
		)
	end	

	def cancel_subscription(uuid)
		subscription = Recurly::Subscription.find(uuid)
		subscription.cancel
	end	

	def reactivate_subscription(uuid)
		subscription = Recurly::Subscription.find(uuid)
		subscription.reactivate
	end	

	def terminate_subscription(uuid)
		subscription = Recurly::Subscription.find(uuid)
		subscription.terminate :partial	
	end	

	def postpone_subscription(uuid)	
		subscription = Recurly::Subscription.find(uuid)
		subscription.postpone Time.utc(2012, 12, 31)
	end

	def postpone_subscription(uuid,next_renewal_date)		
		subscription = Recurly::Subscription.find(uuid)
		# todo : next_nenewal_date
		subscription.postpone Time.utc(2012, 12, 31)
	end	

	def create_subscription_wth_add_on(add_on_code1,add_on_code2)	
		addon1 = Recurly::SubscriptionAddOn.new(add_on_code1)
		addon1.quantity = 2

		addon2 = Recurly::SubscriptionAddOn.new(add_on_code2)
		addon1.quantity = 2
		begin
			Timeout::timeout(Settings.time_out.create_subscription_timeout) do  
				subscription = Recurly::Subscription.create(
				  :plan_code => 'gold',
				  :currency  => 'EUR',
				  :subscription_add_ons => [
				  	addon1,
				  	addon2
				  ],
				  :account   => {
				    :account_code => '1',
				    :email        => 'verena@example.com',
				    :first_name   => 'Verena',
				    :last_name    => 'Example',
				    :billing_info => {
				      :number => '4111-1111-1111-1111',
				      :month  => 1,
				      :year   => 2014,
				    }
				  }
				)
			end
		rescue Timeout::Error 
          internal_error!(TIMEOUT_ERROR,"Timeout occured. ")          
        rescue Errno::ETIMEDOUT
          internal_error!(TIMEOUT_ERROR,"Timeout occured. ")
        rescue Errno::ECONNREFUSED => e      
          internal_error!(CONNECTION_REFUSED, "Connection refused.")  
        end
    end	    

       def add_subscription_add_on(uuid,add_on_code)
	       	subscription = Recurly::Subscription.find(uuid)

			newaddon = Recurly::SubscriptionAddOn.new(add_on_code)
			newaddon.quantity = 2

			subscription.subscription_add_ons = subscription.subscription_add_ons + [ newaddon ]	
       end

       def list_transactions
       		transactions = []
       		Recurly::Transaction.find_each do |transaction|
			  #puts "Transaction: #{transaction.inspect}"
			  transactions << transaction
			end
			transactions

       end	

       def list_account_transactions(account_code)
       		account = Recurly::Account.find(account_code)
       		transactions =[]
			account.transactions.find_each do |transaction|
			  #puts "Transaction: #{transaction.inspect}"
			  transactions << transaction
			end
			transactions

       end

       	def lookup_transaction(id)
       		transaction = Recurly::Transaction.find(id)
       	end

       	def create_transaction
       		account = Recurly::Account.find params[:account_code]
       		transaction = account.transactions.create(
			  :amount_in_cents => params[:amount_in_cents],
			  :currency        => params[:currency],
			  :account         => { :account_code => params[:accout_code] }
			)
       	end

       	def refund_transaction(id)
       		transaction = Recurly::Transaction.find(id)
			transaction.refund(10_00)
       	end	

	

end