class Authentication < ActiveRecord::Base
  include Grape::Entity::DSL
  validates :provider, :uid, :user_id, :presence => true

  attr_accessible :provider, 
  :uid, 
  :user_id, 
  :secret, 
  :link, 
  :name, 
  :access_token,
  :refresh_token, 
  :access_token_expires_at, 
  :code
  
  belongs_to :user, :polymorphic => true
  
  entity :provider, 
  :link, 
  :user_id, 
  :uid, 
  :name,   
  :access_token,
  :refresh_token, 
  :access_token_expires_at, 
  :code do
  end
  
  def self.find_access(access_token)
    where(:access_token => access_token).first
  end
 
  before_create :gen_tokens
  
  def self.prune!
    where(:created_at.lt => 3.days.ago).delete_all
  end
 
  def self.authenticate(code, application_id)
    where(:code => code, :application_id => application_id).first
  end
 
  def start_expiry_period!
    self.update_attribute(:access_token_expires_at, 2.days.from_now)
  end
 
  def redirect_uri_for(redirect_uri)
    if redirect_uri =~ /\?/
      redirect_uri + "&code=#{code}&response_type=code"
    else
      redirect_uri + "?code=#{code}&response_type=code"
    end
  end
 
  protected
  
  def gen_tokens
    self.code, self.access_token, self.refresh_token = SecureRandom.hex(16), SecureRandom.hex(16), SecureRandom.hex(16)
  end
 
end
