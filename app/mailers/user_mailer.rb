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

	def added_to_queue
		@user = params[:user]

		mail(
			to: @user.email,
			subject: "You have been added to today's queue."
		)
	end

	def finished_queue
		@user = params[:user]

		mail(
			to: @user.email,
			subject: "Thank you for visiting."
		)
	end

	def turn_is_up
		@user = params[:user]

		mail(
			to: @user.email,
			subject: "Please enter the doctor's room."
		)
	end

	def queue_cancelled
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
end
