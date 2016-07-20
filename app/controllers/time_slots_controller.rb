class TimeSlotsController < ApplicationController
  before_action :authenticate!, only: [:confirm, :destroy]

  def show
    render json: time_slot
  end

  def confirm
    authorize time_slot

    ConfirmTimeSlot.new(current_user.profile, time_slot).call

    render json: time_slot.event
  end

  def destroy
    authorize time_slot

    time_slot.destroy

    head :no_content
  end

  protected

  def time_slot
    @time_slot ||= TimeSlot.find(params[:id])
  end
end
