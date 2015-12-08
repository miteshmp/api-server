APIServer::Application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" },
  :path_names => { 
  	:sign_in => 'login', 
  	:sign_out => 'logout',
  	:password => 'secret', 
  	:confirmation => 'verification', 
  	:unlock => 'unblock', 
  	:registration => 'register', 
  	:sign_up => 'cmon_let_me_in' }
  #resources :access_tokens, :only => [:create, :destroy]
  #API - GRAPE
  mount Base => "/"
  mount CameraServiceAPI => "/"
  match '*unmatched_route', :to => 'application#raise_not_found!'
end

