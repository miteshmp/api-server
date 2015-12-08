class ApplicationController < ActionController::Base
  protect_from_forgery

	rescue_from ActionController::RoutingError, :with => :render_not_found
	 #render 404 error
	def render_not_found(e)
		respond_to do |format|
			format.json{ render :json => 
				{ :status => 404,
			      :code => ROUTING_ERROR,
			      :message => "Routing error! The submitted URL has some problem or the requested route was not found. Please correct the URL and try again.",
			      :more_info => Settings.error_docs_url %  ROUTING_ERROR
    			}, 
    			:status => 404 }
		end
	end

	 #called by last route matching unmatched routes. Raises RoutingError which will be rescued from in the same way as other exceptions.
	def raise_not_found!
		raise ActionController::RoutingError.new("No route matches #{params[:unmatched_route]}")
	end

end

