class AppointmentsController < ApplicationController
	before_action :set_appointment, only: %i[ show edit update destroy ]
	before_action :set_patients, only: %i[ new ]

	def new
		@appointment = Appointment.new
		@clinics = Clinic.all
	end

	def create
    @appointment = Appointment.new(appointment_params)

    respond_to do |format|
      if @appointment.save
				if current_user.doctor?
					format.html { redirect_to doctor_book_appointment_path, notice: "Appointment successfully set." }
					# format.json { render :show, status: :created, location: @appointment }
				end
      else
				if current_user.doctor?
					format.html { redirect_to doctor_book_appointment_path, alert: "Appointment was not created. #{@appointment.errors.first.full_message}" }
					# format.json { render json: @appointment.errors, status: :unprocessable_entity }
				end
      end
    end
  end

	def destroy
    @appointment.destroy
    flash[:notice] = 'Appointment cancelled!'

		redirect_to patient_dashboard_path if current_user.patient?
		redirect_to doctor_dashboard_path if current_user.doctor?
  end

	def appointments_history
		@appointments = Appointment.where('schedule > ?', DateTime.now)
	end

	private

	def set_patients
		@patients = Patient.all
	end

	def set_appointment
		@appointment = Appointment.find(params[:id] || @appointment.id)
	end

	# Only allow a list of trusted parameters through.
	def appointment_params
		params.require(:appointment).permit(:user_id, :clinic_id, :schedule, :status)
	end
end
