class ClinicSchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_clinic#, except: [:destroy]
  before_action :set_clinic_schedule, only: [:destroy, :edit, :update]

  def index
    @clinic_schedule = ClinicSchedule.new
    @clinic_schedules = @clinic.clinic_schedules
    @days_of_the_week = Date::DAYNAMES
  end

  def edit
    @days_of_the_week = Date::DAYNAMES
  end

  def update
    respond_to do |format|
      if @clinic_schedule.update(clinic_schedule_params)
        format.html { redirect_to clinic_clinic_schedules_url(), notice: "Clinic Schedule was successfully updated." }
        format.json { render :show, status: :ok, location: @clinic_schedule }
      else
        format.html { redirect_to clinic_clinic_schedules_url, alert: "#{@clinic_schedule.errors.first.full_message}" }
        format.json { render json: @clinic_schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @clinic_schedule.destroy

    respond_to do |format|
      format.html { redirect_to clinic_clinic_schedules_url, notice: "Clinic Schedule was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def create
    @clinic_schedule = @clinic.clinic_schedules.new(clinic_schedule_params)
    respond_to do |format|
      if @clinic_schedule.save
          format.html { redirect_to clinic_clinic_schedules_url, notice: "Clinic Schedule created successfully!" }
      else
        format.html { redirect_to clinic_clinic_schedules_url, alert: "Schedule was not created. #{@clinic_schedule.errors.first.message}" }
      end
    end
  end

  private

  def set_clinic
    @clinic = Clinic.find(params[:clinic_id])
  end

  def set_clinic_schedule
    @clinic_schedule = ClinicSchedule.find(params[:id])
  end

  def clinic_schedule_params
    params.require(:clinic_schedule).permit(:day, :start_time, :end_time, :clinic_id, :slots)
  end
end
