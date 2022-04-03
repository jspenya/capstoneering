class ClinicQueuesController < ApplicationController
  def show
    @clinic_queue = ClinicQueue.find_by( schedule: DateTime.now.beginning_of_day..DateTime.now.end_of_day )
    @patient = Patient.new
  end

  def edit
  end

  def update
  end

  def setup_show_page
    if ClinicQueue.find_by(schedule: DateTime.now.beginning_of_day..DateTime.now.end_of_day ).present?
      clinic_queue_id = ClinicQueue.find_by( schedule: DateTime.now.beginning_of_day..DateTime.now.end_of_day ).id
    else
      clinic_queue = ClinicQueue.create(schedule: DateTime.now.beginning_of_day)

      clinic_queue_id = clinic_queue.id
    end

    redirect_to action: :show, id: clinic_queue_id
  end
end
