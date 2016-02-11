require 'concerns/acts_as_verifiable'

class User < ApplicationRecord
  has_one :profile, dependent: :nullify

  has_secure_token :authentication_token

  after_create :build_profile

  acts_as_verifiable :email,
    delivery: UserMailer, token: -> { Token.friendly }

  acts_as_verifiable :phone_number,
    delivery: UserSMSer,  token: -> { Token.pin }

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :trackable,
         :validatable

  validates :first_name,   presence: true, length: { maximum: 64 }
  validates :last_name,    presence: true, length: { maximum: 64 }
  validates :birthday,     presence: true, date: {
    after:              Proc.new { 100.year.ago },
    before_or_equal_to: Proc.new {  18.year.ago }
  }
  validates :phone_number, uniqueness: true, allow_nil: true
  validates_plausible_phone :phone_number

  def build_profile
    create_profile(display_name: "#{first_name} #{last_name.capitalize.chr}")
  end
end
