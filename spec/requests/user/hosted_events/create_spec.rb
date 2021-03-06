require 'rails_helper'

RSpec.describe 'User create hosted event', :type => :request do
  let(:event_params) { event.attributes.merge('new_time_slots' => event.new_time_slots) }

  let(:params) { Serialize.params(event_params, type: :events) }

  before do
    post user_hosted_events_path, params: params, headers: json_headers
  end

  it_behaves_like 'an action requiring authentication'

  context 'when user is authenticated' do
    let(:user) { FactoryGirl.create(:user_verified) }

    let(:authenticate) { user }

    include_examples 'check parameters for', :events

    context 'when attributes are valid' do
      let(:event) { FactoryGirl.build(:event) }

      let(:created_event) { user.hosted_events.first }

      it { is_expected.to return_status_code 201 }

      it 'creates a new event with permited parameters' do
        permited_params = event.slice(
          :title, :category, :min_capacity, :ambiance, :level, :capacity, :auto_accept,
          :short_description, :description, :street, :postcode, :city, :state,
          :country, :private
        )
        expect(created_event).to have_attributes(permited_params)

        expect(created_event.begin_at).to equal_time(event.begin_at)
        expect(created_event.end_at).to   equal_time(event.end_at)
      end

      it 'returns the event attributes' do
        expect(response.body).to equal_serialized(created_event)
      end

      it 'grants the user with an early event achievement' do
        expect(user).to have_achievement('early-event')
      end

      it "doesn't grant the user with a first flexible event achievement" do
        expect(user).to_not have_achievement('first-flexible-event')
      end

      it "doesn't grant the user with a first recurrent event achievement" do
        expect(user).to_not have_achievement('first-recurrent-event')
      end

      context 'with flexible event' do
        let(:event) { FactoryGirl.build(:event, :flexible) }

        it 'creates associated times slots' do
          expect(created_event.time_slots).to_not be_empty
        end

        it 'grants the user with a first flexible event achievement' do
          expect(user).to have_achievement('first-flexible-event')
        end

        it "doesn't grant the user with a first recurrent event achievement" do
          expect(user).to_not have_achievement('first-recurrent-event')
        end
      end

      context 'with event with unlimited capacity' do
        let(:event) { FactoryGirl.build(:event, :unlimited_access) }

        it 'grants the user with a first flexible event achievement' do
          expect(user).to have_achievement('first-unlimited-event-capacity')
        end
      end

      context 'with recurrent event' do
        let(:event) { FactoryGirl.build(:event, :recurrent) }

        it 'creates associated children' do
          expect(created_event.children).to_not be_empty
        end

        it 'grants the user with a first recurrent event achievement' do
          expect(user).to have_achievement('first-recurrent-event')
        end

        it "doesn't grant the user with a first flexible event achievement" do
          expect(user).to_not have_achievement('first-flexible-event')
        end
      end
    end

    context 'when attributes are invalid' do
      let(:event) { Event.new }

      it { is_expected.to return_validation_errors :event }
    end
  end
end
