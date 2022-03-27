class AppointmentsController < ApplicationController

	private

	def set_appointment
		@appointment = Appointment.find(params[:id] || @appointment.id)
	end

	# Only allow a list of trusted parameters through.
	def appointment_params
		params.require(:appointment).permit(:user_id, :clinic_id :schedule, :status)
	end
end
