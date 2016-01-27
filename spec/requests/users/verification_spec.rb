require 'rails_helper'

RSpec.describe 'Users verification', :type => :request do
  before do
    put users_verifications_path, params: verification_params, headers: json_headers
  end

  let(:verification_params) {}

  it_behaves_like 'an action requiring authentication'

  context 'when user is authenticated' do
    let(:user)          { FactoryGirl.create(:user) }
    let(:authenticated) { true }

    let(:verification) do
      Verification.new(verification_params[:verification], user: user)
    end

    context 'with empty parameters' do
      let(:verification_params) { {} }

      it { is_expected.to return_validation_errors :verification }
    end

    context 'with invalid type' do
      let(:verification_params) { { verification: { type: :invalid } } }

      it { is_expected.to return_validation_errors :verification }
    end

    context 'with email type' do
      let(:verification_params) do
        { verification: { type: :email, token: user.email_verification_token } }
      end

      before do
        user.reload
      end

      context 'when user email is not verified' do
        let(:user) do
          FactoryGirl.create(:user).tap(&:generate_email_verification_token!)
        end

        it { is_expected.to return_no_content }

        it 'completes user email verification' do
          expect(user.email_verified_at).to equal_time(Time.now)
        end
      end

      context 'when user email is already verified' do
        let(:user) { FactoryGirl.create(:user).tap(&:verify_email!) }

        it do
          is_expected.to return_validation_errors :verification,
            context: :complete
        end
      end

      context 'when email verification token has expired' do
        let(:user) do
          FactoryGirl.create(:user).tap do |user|
            user.generate_email_verification_token!
            user.update(email_verification_sent_at: Time.now - 6.hours)
          end
        end

        it do
          is_expected.to return_validation_errors :verification,
            context: :complete
        end
      end

      context 'when email verification token is invalid' do
        it do
          is_expected.to return_validation_errors :verification,
            context: :complete
        end
      end
    end
  end
end
