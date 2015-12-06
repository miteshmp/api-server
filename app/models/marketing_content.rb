class MarketingContent < ActiveRecord::Base
  include Grape::Entity::DSL
  audited
  acts_as_paranoid

  attr_accessible :key, :value, :updated_at

  validates :key, presence: true, :allow_nil => false, uniqueness: { case_sensitive: false }

  default_value_for :value, ""

  entity :key, :value do
    expose :value, if: { type: :full }
    expose :created_at, if: { type: :full }
    expose :updated_at, if: { type: :full }
  end

end
