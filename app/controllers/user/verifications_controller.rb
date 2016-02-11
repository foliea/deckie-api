class User::VerificationsController < ApplicationController
  before_action :authenticate!

  before_action -> { check_parameters_for :verifications }

  def create
    unless verification.send_instructions
      return render_validation_errors(verification)
    end
    head :no_content
  end

  def update
    unless verification.complete
      return render_validation_errors(verification)
    end
    head :no_content
  end

  protected

  def verification
    @verification ||= Verification.new(verification_params, model: current_user)
  end

  def verification_params
    resource_attributes.permit(:type, :token)
  end
end
