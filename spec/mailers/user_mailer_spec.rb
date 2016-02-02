require 'rails_helper'

RSpec.describe UserMailer do
  let(:user) { FactoryGirl.create(:user)  }

  describe '#reset_password_instructions' do
    # We need to get the raw token generated by devise, not the one saved in
    # the database.
    let(:reset_password_token) { user.send(:set_reset_password_token) }

    let(:mail) { UserMailer.reset_password_instructions(user, reset_password_token) }

    include_examples 'renders the email headers with', {
      subject:  I18n.t('devise.mailer.reset_password_instructions.subject'),
      to:       :user,
      from:     :notifications,
      reply_to: :notifications
    }

    include_examples 'assigns', :user, :email

    it 'assigns @reset_password_url' do
      expect(mail.body.encoded).to include(
        user_reset_password_url << "/edit?reset_password_token=#{reset_password_token}"
      )
    end
  end

  describe '#email_verification_instructions' do
    let(:mail) { UserMailer.email_verification_instructions(user) }

    before do
      user.generate_email_verification_token!
    end

    include_examples 'renders the email headers with', {
      subject:  I18n.t('verifications.email.subject'),
      to:       :user,
      from:     :notifications,
      reply_to: :notifications
    }

    include_examples 'assigns', :user, :email

    it 'assigns @email_verification_url' do
      expect(mail.body.encoded).to include(
        user_verifications_url << "/email?token=#{user.email_verification_token}"
      )
    end
  end
end
