class UserMailer < ApplicationMailer
	default from: 'notifications@example.com'

  def reschedule_notice
		@users = params[:users]

		@users.each do |user|
			@user = user
			# @appointment = user.appointment #Attach appointment

			mail(
				to: user.email,
				subject: "Hi #{user.firstname}. Your appointment is cancelled."
			)
		end
  end

	def appointment_created
		@user = params[:user]

		mail(
			to: @user.email,
			subject: "Successfully booked an appointment!"
		)
	end
end
