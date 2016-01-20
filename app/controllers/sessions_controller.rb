class SessionsController < Devise::SessionsController
  respond_to :json

  def create
    super do |user|
      render json: { token: user.authentication_token }, status: 201 and return
    end
  end
end
