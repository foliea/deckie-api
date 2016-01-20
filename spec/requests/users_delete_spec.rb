require 'rails_helper'

RSpec.describe 'DELETE /users', :type => :request do
  before do
    delete '/users', {}, json_headers
  end

  it_behaves_like 'an action requiring authentication'

  context 'when user is authenticated' do
    let(:user)          { FactoryGirl.create(:user) }
    let(:authenticated) { true }

    it { is_expected.to return_no_content }

    it 'deletes the user' do
      expect(User.find_by(email: user.email)).to_not be_present
    end
  end
end
