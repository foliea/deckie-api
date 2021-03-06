class ProfilesController < ApplicationController
  before_action :authenticate!, only: [:update]

  def show
    render json: profile
  end

  def update
    authorize profile

    unless profile.update(profile_params)
      return render_validation_errors(profile)
    end
    # After updating a profile with a new avatar, the record must be reloaded
    # in order to have the avatar url.
    render json: profile.reload
  end

  protected

  def profile
    @profile ||= Profile.find(params[:id])
  end

  def profile_params
    permited_attributes(profile)
  end
end
