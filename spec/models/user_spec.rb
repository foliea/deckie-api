require 'rails_helper'

RSpec.describe User, :type => :model do
  describe 'Database' do
    [
      :email,
      :authentication_token,
      :reset_password_token,
      :email_verification_token,
      :phone_number_verification_token
    ].each do |attribute|
      it { is_expected.to have_db_index(attribute).unique(true) }
    end

    it do
      is_expected.to have_db_column(:first_name).of_type(:string).with_options(null: false)
    end

    it do
      is_expected.to have_db_column(:last_name).of_type(:string).with_options(null: true)
    end

    it do
      is_expected.to have_db_column(:birthday).of_type(:date).with_options(null: true)
    end

    it do
      is_expected.to have_db_column(:preferences)
        .of_type(:jsonb).with_options(null: false, default: {})
    end

    it do
      is_expected.to have_db_column(:notifications_count)
        .of_type(:integer).with_options(null: false, default: 0)
    end

    [:organization, :moderator].each do |attribute|
      it do
        is_expected.to have_db_column(attribute)
          .of_type(:boolean).with_options(null: false, default: false)
      end
    end
  end

  describe 'Validations' do
    subject { FactoryGirl.build(:user_with_phone_number) }

    [
      :first_name,  :last_name, :birthday, :email, :password, :culture
    ].each do |attribute|
      it { is_expected.to validate_presence_of(attribute) }
    end

    it do
      is_expected.to validate_uniqueness_of(:email).case_insensitive
    end

    it { is_expected.to validate_length_of(:first_name).is_at_most(64) }
    it { is_expected.to validate_length_of(:last_name).is_at_most(64) }

    it { is_expected.to validate_plausible_phone(:phone_number) }

    it { is_expected.to validate_date_after(:birthday,  { limit: 100.year.ago }) }
    it { is_expected.to validate_date_before(:birthday, { limit: 18.year.ago + 1.day }) }

    it { is_expected.to validate_inclusion_of(:culture).in_array(%w(en fr)) }

    it { is_expected.to_not allow_value(nil).for(:organization) }

    context 'with a previous user older than limits' do
      subject { FactoryGirl.create(:user_elder) }

      it { is_expected.to be_valid }

      context 'when updating birthday' do
        it { is_expected.to validate_date_after(:birthday, { limit: 100.year.ago }) }
      end
    end

    context 'with an organization' do
      subject { FactoryGirl.create(:user, :organization) }

      it { is_expected.to validate_absence_of(:last_name) }

      it { is_expected.to validate_absence_of(:birthday) }
    end
  end

  describe 'Relationships' do
    it { is_expected.to have_one(:profile).dependent(:destroy) }

    it { is_expected.to have_many(:notifications).dependent(:destroy) }

    it { is_expected.to have_many(:email_deliveries).dependent(:destroy) }
  end

  context 'after create' do
    subject(:user) { FactoryGirl.create(:user, [:moderator, :organization].sample) }

    it 'has an authentication token' do
      expect(user.authentication_token).to be_valid_token :secure
    end

    it 'has a profile properly propagated' do
      expect_profile_propagation
    end

    it 'is not verified' do
      expect(user).not_to be_verified
    end

    it 'has subscribed to all notifications' do
      expect(user.preferences['notifications']).to eq(Notification.types)
    end
  end

  context 'after update' do
    subject(:user) { FactoryGirl.create(:user) }

    let(:user_update) do
      FactoryGirl.build([:user_update, :user_verified].sample)
    end

    [
      :first_name, :last_name, :email_verified_at, :phone_number_verified_at, :moderator
    ].each do |attribute|
      context "with #{attribute}" do
        before do
          user.update(attribute => user_update.send(attribute))
        end

        it 'updates its profile' do
          expect_profile_propagation
        end
      end
    end
  end

  def expect_profile_propagation
    expect(user.profile).to have_attributes({
      display_name:          user.display_name,
      email_verified:        user.email_verified?,
      phone_number_verified: user.phone_number_verified?,
      moderator:             user.moderator?,
      organization:          user.organization?
    })
  end

  it_behaves_like 'acts as paranoid'

  it_behaves_like 'acts as verifiable', :email,
    carrier: UserMailer,
    faker: -> { Faker::Internet.email },
    token_type: :friendly

  it_behaves_like 'acts as verifiable', :phone_number,
    carrier: UserSMSer,
    faker: -> { Fake::PhoneNumber.plausible },
    token_type: :pin

  describe '#verified?' do
    subject(:verified?) { user.verified? }

    before { verified? }

    [:email, :phone_number].each do |attribute|
      context "when user #{attribute} is not verified" do
        let(:user) { FactoryGirl.create(:"user_with_#{attribute}_verified") }

        it { is_expected.to be_falsy }
      end
    end

    context 'when user is verified' do
      let(:user) { FactoryGirl.create(:user_verified) }

      it { is_expected.to be_truthy }
    end
  end

  [:invitations, :hosted_events, :time_slot_submissions].each do |method_name|
    describe "##{method_name}" do
      let(:user) { FactoryGirl.create(:user_with_hosted_events) }

      subject { user.public_send(method_name) }

      it "delegates its profile #{method_name}" do
        is_expected.to eq(user.profile.public_send(method_name))
      end
    end
  end

  describe '#opened_hosted_events' do
    let(:user) { FactoryGirl.create(:user_with_hosted_events) }

    subject { user.opened_hosted_events }

    it 'returns the user profile opened hosted events' do
      is_expected.to eq(user.profile.opened_hosted_events)
    end
  end

  describe '#opened_submissions' do
    let(:user) { FactoryGirl.create(:user, :with_submissions) }

    subject { user.opened_submissions }

    it 'returns the user submissions to opened events' do
      is_expected.to eq(user.submissions.filter({ event: :opened }))
    end
  end

  describe '#reset_notifications_count!' do
    let(:user) do
      FactoryGirl.create(:user, notifications_count: Faker::Number.between(1, 5))
    end

    it 'sets the notifications_count to 0' do
      expect { user.reset_notifications_count! }.to change { user.notifications_count }.to(0)
    end
  end

  describe '#host_of?' do
    let(:host) { FactoryGirl.create(:user_with_hosted_events) }

    let(:user) { FactoryGirl.create(:user) }

    subject(:host_of?) { host.host_of?(user) }

    it { is_expected.to be_falsy }

    context 'when user is an attendee of at least of event of the host' do
      before do
        event = host.hosted_events.sample

        event.update(auto_accept: true)

        JoinEvent.new(user.profile, event).call
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#notifications_to_send' do
    let(:user) do
      FactoryGirl.create(:user, :with_notifications, :with_random_subscriptions)
    end

    subject(:notifications_to_send) { user.notifications_to_send }

    it 'equals to its sendable notifications' do
      is_expected.to eq(
        user.notifications.where(sent: false, type: user.preferences['notifications'])
      )
    end
  end

  describe '#welcome' do
    let(:user) { FactoryGirl.create(:user) }

    let(:informations_mail) { double(deliver_later: true) }

    it 'delivers later a welcome informations email' do
      allow(UserMailer).to receive(:welcome_informations).with(user)
        .and_return(informations_mail)

      expect(informations_mail).to receive(:deliver_later).with(no_args)

      user.welcome
    end
  end

  describe '#received_email?' do
    let(:user) { FactoryGirl.create(:user) }

    let(:resource) { FactoryGirl.create(:event) }

    subject { user.received_email?(:test, resource) }

    context 'when user already received the according email delivery' do
      before { EmailDelivery.create(type: :test, receiver: user, resource: resource) }

      it { is_expected.to be_truthy }
    end

    context "when user doesn't receive the according email delivery" do
      it { is_expected.to be_falsy }
    end
  end

  describe '#deliver_email' do
    let(:user) { FactoryGirl.create(:user) }

    let(:resource) { FactoryGirl.create(:event) }

    let(:reminder_mail) { double(deliver_now: true) }

    before do
      allow(UserMailer).to receive(:flexible_event_reminder).with(user, resource)
        .and_return(reminder_mail)

      user.deliver_email(:flexible_event_reminder, resource)
    end

    it 'delivers the appropriate mail' do
      expect(reminder_mail).to have_received(:deliver_now).with(no_args)
    end

    it 'creates the appropriate email delivery for the user' do
      expect(
        EmailDelivery.find_by(type: :flexible_event_reminder, receiver: user, resource: resource)
      ).to be_present
    end
  end

  describe '#display_name' do
    let(:user) { FactoryGirl.create(:user) }

    subject { user.display_name }

    it { is_expected.to eq("#{user.first_name} #{user.last_name.capitalize[0]}") }

    context 'with organization' do
      let(:user) { FactoryGirl.create(:user, :organization) }

      it { is_expected.to eq(user.first_name) }
    end
  end
end
