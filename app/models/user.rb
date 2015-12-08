class User < ActiveRecord::Base
  model_stamper
  audited except: [:password, :authentication_token, :encrypted_password,:remember_me]
  has_associated_audits
  acts_as_paranoid
  
  include Grape::Entity::DSL
  extend Enumerize

  scope :with_role, lambda { |role| {:conditions => "roles_mask & #{2**ROLES.index(role.to_s)} > 0"} }
  self.per_page = Settings.default_page_size

  
  devise :database_authenticatable,
  :registerable,
  :recoverable,
  :rememberable,
  :trackable,
  :validatable,
  :omniauthable,
  :lockable,
  :token_authenticatable
  
  has_many :authentications, :dependent => :destroy
  has_many :devices, :dependent => :destroy
  has_many :apps, :dependent => :destroy
  has_many :device_master
  has_many :devices_shared_by_me, :class_name => 'SharedDevice', :foreign_key => 'shared_by'
  has_many :devices_shared_with_me, :class_name => 'SharedDevice', :foreign_key => 'shared_with'

  # belongs_to :secondary_user
  

  # Allow people to log in with username (from oauth provider) or email
  attr_accessor :login

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login,
  :name,
  :email,  
  :encrypted_password,
  :remember_me,
  :authentication_token,
  :roles,
  :password



  entity :id,
  :email,
  :name,
  :roles,
  :created_at,
  :updated_at,
  :last_sign_in_at,
  :last_sign_in_ip,
  :sign_in_count  do
  end

  validates :password, :confirmation => true, :length => { :in => 8..50 }, :if => :should_validate_password?
  validates :password_confirmation, :presence => true,  :if => :should_validate_password?
  validates :name, presence: true, :allow_nil => false, uniqueness: { case_sensitive: false }, :length => { :in => 3..25 }
  #validates :email, presence: true, :allow_nil => false, :length => { :in => 5..255 }, :format => { :with => RubyRegex::Email }

  validates :name, format: { with: /\A[a-zA-Z0-9_.-]*\z/,
    message: Settings.invalid_format_message }

  default_value_for :name, ""
  default_value_for :email, ""

  after_create :send_email
  
  attr_accessor :updating_password


  def should_validate_password?
    updating_password || new_record?
  end

  def send_email
    if !self.email.nil? && !self.email.is_empty?
       Thread.new {
        Notifier.welcome(self.email).deliver
      }
    end    
  end 
  

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  def self.find_for_token_authentication(params = {})
   return nil unless params["access_token"]

   user = User.where(:authentication_token  => params["access_token"]).first

   unless user 
    access = Authentication.find_access(params["access_token"])
    user = User.find(access.user_id) if access
  end
  return user
end

def self.new_with_session(params, session)
  super.tap do |user|
    if data = session["devise.facebook_data"]
      user.email = data["email"]
    end
  end
end

  #Override Devise's update with password to allow registration edits without password entry
  def update_with_password(params={})
    params.delete(:current_password)
    self.update_without_password(params)
  end

  # Update user record and create or update authentication record
  def set_token_from_hash(auth_hash, user_hash)
    self.update_attribute(:name, user_hash[:name]) if self.name.blank?
    self.update_attribute(:email, user_hash[:email]) if self.email.blank?
    token = self.authentications.find_or_initialize_by_provider_and_uid(auth_hash[:provider], auth_hash[:uid])
    token.update_attributes(
      :name => auth_hash[:name],
      :link => auth_hash[:link],
      :access_token => auth_hash[:token],
      :secret => auth_hash[:secret]
      )
  end

  def has_authorization_to?(action, model_or_instance)
    a = Ability.new(self).can? action.to_sym, model_or_instance
  end

  def can_access_device?(action, device, user)
    ability = Ability.new(self).can? action.to_sym, device
    unless ability
      shared_device = device.shared_devices.where(shared_with: user.id).first
      ability = shared_device ? true : false
    end 
    ability 
  end
  def roles=(roles)
    self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)
  end

  def roles
    ROLES.reject do |r|
      ((roles_mask.to_i || 0) & 2**ROLES.index(r)).zero?
    end
  end

  def is?(role)
    roles.include?(role.to_s)
  end
  
  protected

  # From Devise docs to allow name or email as login
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(name) = :value OR lower(email) = :value", { :value => login.downcase }]).first
  end

  class << self
    def get(id)
      User.where(id: id).first
    end

    def authenticate(u, p)
      id = User::USERS.invert[u]
      User.new(id, u) if id
    end
  end
end
