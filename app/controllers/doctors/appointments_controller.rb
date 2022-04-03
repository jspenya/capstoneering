class Doctors::AppointmentsController < DoctorsController
	before_action :authenticate_user!
  before_action :set_appointment, except: :index
  before_action :set_clinic, only: :index

	def index
		@appointments = @clinic.appointments.doctor_appointments_today
		@appointments_upcoming_today = @clinic.appointments.upcoming_appointments_today
	end

	private
	def set_appointment
		@appointment = Appointment.find(params[:appointment_id])
	end

	def set_clinic
		clinic_id = ClinicSchedule.where(day: Date.today.strftime("%A")).first.clinic_id

		@clinic = Clinic.find(clinic_id)
	end
end
