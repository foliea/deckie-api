require 'concerns/acts_as_verifiable'

class User < ApplicationRecord
  has_one :profile, dependent: :nullify

  delegate :hosted_events, to: :profile
  delegate :subscriptions, to: :profile

  has_secure_token :authentication_token

  after_create :build_profile

  after_update :update_profile, if: -> { first_name_changed? || last_name_changed? }

  before_destroy :destroy_opened_events

  acts_as_verifiable :email,
    delivery: UserMailer, token: -> { Token.friendly }

  acts_as_verifiable :phone_number,
    delivery: UserSMSer,  token: -> { Token.pin }

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :trackable,
         :validatable

  validates :first_name, :last_name, presence: true, length: { maximum: 64 }

  validates :birthday, presence: true, date: {
    after:              Proc.new { 100.year.ago },
    before_or_equal_to: Proc.new {  18.year.ago }
  }
  validates :culture, presence: true, inclusion: { in: %w(en) }

  validates_plausible_phone :phone_number

  def verified?
    unless verified = email_verified? && phone_number_verified?
      errors.add(:base, :unverified)
    end
    verified
  end

  protected

  def build_profile
    create_profile(display_name: display_name)
  end

  def update_profile
    profile.update(display_name: display_name)
  end

  def destroy_opened_events
    hosted_events.opened.destroy_all
  end

  def display_name
    "#{first_name} #{last_name.capitalize.chr}"
  end
end
