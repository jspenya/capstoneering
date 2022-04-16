class PatientDashboardsController < ApplicationController
	before_action :set_patient, only: %i[ dashboard book_appointment ]
	before_action :authenticate_user!

	def dashboard
		@appointments_to_attend = @patient.appointments.where('schedule > ?', Time.now.utc)
	end

	def book_appointment
		@clinics = Clinic.all
		@clinic = Clinic.first
		@clinic = Clinic.find(params[:clinic_id]) if params[:clinic_id].present?

		respond_to do |format|
			format.html {  }
			format.js
		end
	end

	def create_appointment
		@appointment = current_user.appointments.new(
			schedule: params[:schedule],
			user_id: current_user.id,
			clinic_id: params[:clinic_id]
		)
		if @appointment.save
			redirect_to patient_book_appointment_url, notice: "Appointment set successfully!"
		else
			redirect_to patient_book_appointment_url, notice: "Appointment was not created. #{@appointment.errors.first.full_message}"
		end
	end

	def week_appointments
		# start = Time.zone.now
		@appointments = Appointment.current_week
	end

	private
	def set_patient
		@patient = current_user
	end
end
