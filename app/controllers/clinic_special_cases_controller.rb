class ClinicSpecialCasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_clinic_schedule
  before_action :set_clinic_special_case, only: [:show, :destroy]

  def index
    @clinic_special_cases = ClinicSpecialCase.all
  end

  def new
  end

  def edit
  end

  def create
    @clinic_special_case = ClinicSpecialCase.new(
      reason: params[:reason],
      day: params[:day],
      slots: params[:slots],
      start_time: params[:start_time],
      end_time: params[:end_time],
      clinic_schedule_id: params[:clinic_schedule_id]
    )

    if @clinic_special_case.save
      redirect_to clinic_schedule_clinic_special_cases_path, notice: "Special case added!"
    else
      redirect_to clinic_schedule_clinic_special_cases_path, alert: "Special case cannot be saved. #{@clinic_special_case.errors.first.full_message}"
    end
  end

  def destroy
    @clinic_special_case.destroy

    redirect_to clinic_schedule_clinic_special_cases_path, notice: "Successfully deleted Clinic Special Case!"
  end
  
  private
  def set_clinic_special_case
    @clinic_special_case = ClinicSpecialCase.find(params[:id])
  end

  def set_clinic_schedule
    @clinic_schedule = ClinicSchedule.find(params[:clinic_schedule_id])
  end

  def clinic_special_case_params
    params.require(:clinic_special_case).permit(:day, :start_time, :end_time, :reason, :clinic_schedule_id)
  end
end
