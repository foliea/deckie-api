require 'rails_helper'

RSpec.describe VerificationPolicy do
  subject { VerificationPolicy.new(user, verification) }

  [:email, :phone_number].each do |attribute|
    context "with #{attribute} verification" do
      let(:verification) { Verification.new({ type: attribute }, model: user) }

      context "being a user with unverified #{attribute}" do
        let(:user) { FactoryGirl.create(:user_with_phone_number) }

        it { is_expected.to permit_action(:create) }
      end

      context "being a user with verified #{attribute}" do
        let(:user) { FactoryGirl.create(:"user_with_#{attribute}_verified") }


        it { is_expected.to forbid_action(:create) }

        it do
          is_expected.to have_authorization_error(
            :"#{attribute}_already_verified", on: :create
          )
        end
      end

      context "being a user with unspecified #{attribute}" do
        let(:user) do
          FactoryGirl.create(:user).tap do |user|
            user.public_send("#{attribute}=", nil)
          end
        end

        it { is_expected.to forbid_action(:create) }

        it do
          is_expected.to have_authorization_error(
            :"#{attribute}_unspecified", on: :create
          )
        end
      end
    end
  end
end
