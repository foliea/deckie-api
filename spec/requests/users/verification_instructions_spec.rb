require 'rails_helper'

RSpec.describe 'Users verification instructions', :type => :request do
  before do
    post users_verifications_path, params: verification_params, headers: json_headers
  end

  let(:verification_params) {}

  it_behaves_like 'an action requiring authentication'

  context 'when user is authenticated' do
    let(:user)          { FactoryGirl.create(:user) }
    let(:authenticated) { true }

    let(:verification) do
      Verification.new(verification_params[:verification], user: user)
    end

    before do
      MailDeliveries.clear
    end

    context 'with empty parameters' do
      let(:verification_params) { {} }

      it { is_expected.to return_validation_errors :verification }
      it { is_expected.not_to have_sent_mail }
    end

    context 'with invalid type' do
      let(:verification_params) { { verification: { type: :invalid } } }

      it { is_expected.to return_validation_errors :verification }
      it { is_expected.not_to have_sent_mail }
    end

    context 'with email type' do
      let(:verification_params) { { verification: { type: :email } } }

      context 'when user email is not verified' do
        it { is_expected.to return_no_content }

        it 'sends an email with verification instructions' do
          expect(MailDeliveries.last).to equal_mail(
            UserMailer.email_verification_instructions(user)
          )
        end
      end

      context 'when user email is already verified' do
        let(:user) { FactoryGirl.create(:user).tap(&:verify_email!) }

        it do
          is_expected.to return_validation_errors :verification,
            context: :send_instructions
        end

        it { is_expected.not_to have_sent_mail }
      end
    end
  end
end
