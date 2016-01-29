class Verification
  include ActiveModel::Validations

  attr_accessor :type, :token

  def initialize(attributes = {}, user: nil)
    attributes = attributes || {}

    # Allow type to be set with a symbol for conveniency.
    @type  = (attributes[:type]  || '').to_s
    @token =  attributes[:token] || ''
    @user  = user
  end

  validates :type, inclusion: { in: %w(email phone_number) }

  validate :user_must_be_unverified, on: [:send_instructions, :complete]

  validate :token_must_be_valid, on: :complete

  def send_instructions
    return false unless valid? && valid?(:send_instructions)

    @user.send("generate_#{@type}_verification_token!")
    @user.send("send_#{@type}_verification_instructions")
  end

  def complete
    return false unless valid? && valid?(:complete)

    @user.send("verify_#{@type}!")
  end

  private

  def user_must_be_unverified
    verified_at = @user.send("#{@type}_verified_at")

    errors.add(:type, :already_verified) unless verified_at.nil?
  end

  def token_must_be_valid
    user_token = @user.send("#{@type}_verification_token")

    if @token.blank? || @token != user_token || sent_at < 5.hours.ago
      errors.add(:token, :invalid)
    end
  end

  def sent_at
    @user.send("#{@type}_verification_sent_at")
  end
end
