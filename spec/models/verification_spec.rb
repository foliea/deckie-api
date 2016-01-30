require 'rails_helper'

RSpec.describe Verification, :type => :model do
  it do
    is_expected.to validate_inclusion_of(:type)
      .in_array(%w(email phone_number))
  end

  let(:user) { FactoryGirl.create(:user_with_phone_number) }

  before do
    SMSDeliveries.use_fake_provider
  end

  after do
    MailDeliveries.clear
    SMSDeliveries.clear
  end

  [:email, :phone_number].each do |attribute|
    describe '#send_instructions' do
      context 'when type is invalid' do
        let(:verification) { Verification.new({ type: nil }, model: user) }

        before do
          verification.type = nil
        end

        include_examples 'fails to send verification for', attribute
      end

      context "when type is #{attribute}" do
        let(:verification) { Verification.new({ type: attribute }, model: user) }

        context 'when model has no attribute to verify' do
          before do
            user.send("#{attribute}=", nil)
          end

          include_examples 'fails to send verification for', attribute
        end

        context "when #{attribute} is already verified" do
          let(:user) { FactoryGirl.create(:"user_with_#{attribute}_verified") }

          include_examples 'fails to send verification for', attribute
        end

        context 'when everything is valid' do
          it 'returns true' do
            expect(verification.send_instructions).to be_truthy
          end

          it 'generate an email verification token for the model' do
            expect(verification.model).to receive(:"generate_#{attribute}_verification_token!")

            verification.send_instructions
          end

          it 'sends an email with verification instructions to the model' do
            expect(verification.model).to receive(:"send_#{attribute}_verification_instructions")

            verification.send_instructions
          end

          it 'has no error' do
            verification.send_instructions

            expect(verification.errors).to be_empty
          end
        end
      end
    end

    describe '#complete' do
      context 'when type is invalid' do
        let(:verification) { Verification.new({ type: nil }, model: user) }

        include_examples 'fails to complete verification for', attribute
      end

      context "when type is #{attribute}" do
        let(:verification) { Verification.new({ type: attribute }, model: user) }

        context 'when already verified' do
          let(:user) { FactoryGirl.create(:"user_with_#{attribute}_verified") }

          include_examples 'fails to complete verification for', attribute
        end

        context 'when verification token is invalid' do
          before do
            verification.token = nil
          end

          include_examples 'fails to complete verification for', attribute
        end

        context "when model has no #{attribute} verification token" do
          let(:user) { FactoryGirl.create(:user) }

          before do
            verification.token = Faker::Internet.password
          end

          include_examples 'fails to complete verification for', attribute
        end

        context "when verification token doesn't match the model token" do
          let(:user) { FactoryGirl.create(:"user_with_#{attribute}_verification") }

          before do
            model_token = user.send("#{attribute}_verification_token")

            verification.token = "#{model_token}."
          end

          include_examples 'fails to complete verification for', attribute
        end

        context 'when verification token matches the model token' do
          let(:user) { FactoryGirl.create(:"user_with_#{attribute}_verification") }

          before do
            model_token = user.send("#{attribute}_verification_token")

            verification.token = model_token
          end

          it 'returns true' do
            expect(verification.complete).to be_truthy
          end

          it "verifies the model #{attribute}"  do
            expect(verification.model).to receive(:"verify_#{attribute}!")

            verification.complete
          end

          it 'has no error' do
            verification.complete

            expect(verification.errors).to be_empty
          end

          context 'when verification token has expired' do
            let(:user) { FactoryGirl.create(:"user_with_#{attribute}_verification_expired") }

            include_examples 'fails to complete verification for', attribute
          end
        end
      end
    end
  end
end
