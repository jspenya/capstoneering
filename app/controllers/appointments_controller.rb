class AppointmentsController < ApplicationController
	before_action :set_appointment

	def destroy
    @appointment.destroy
    flash[:notice] = 'Appointment cancelled!'

		redirect_to patient_dashboard_path if current_user.patient?
  end

	private

	def set_appointment
		@appointment = Appointment.find(params[:id] || @appointment.id)
	end

	# Only allow a list of trusted parameters through.
	def appointment_params
		params.require(:appointment).permit(:user_id, :clinic_id, :schedule, :status)
	end
end
