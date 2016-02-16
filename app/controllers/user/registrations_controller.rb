class User::RegistrationsController < Devise::RegistrationsController
  alias_method :authenticate_user!, :authenticate!

  before_action :authenticate!, only: :show

  before_action -> { check_parameters_for :users }, only: [:create, :update]

  def show
    render json: current_user, status: :ok
  end

  def create
    super do |user|
      return render_validation_errors(user) unless user.persisted?

      render json: user, status: :created and return
    end
  end

  def update
    super do |user|
      # If current_password is invalid, devise is not setting properly
      # the user (user.valid? will be true but errors will still appear in
      # user.errors).
      return render_validation_errors(user) unless user.errors.empty?

      render json: user, status: :ok and return
    end
  end

  def destroy
    super { head :no_content and return }
  end

  protected

  def sign_up_params
    resource_attributes.permit(shared_attributes)
  end

  def account_update_params
    resource_attributes.permit(shared_attributes.push(:current_password))
  end

  def shared_attributes
    [:email, :password, :first_name, :last_name, :birthday, :phone_number, :culture]
  end
end