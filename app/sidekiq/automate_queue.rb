require 'sidekiq-scheduler'

class AutomateQueue
  include Sidekiq::Worker

  def perform()
    logger.info "!!!!!!STARTING!!!!!"

		return if clinic_queues.nil?
		return if clinic_queues.empty?

		# If current_time >= schedule sa ClinicQueue.where(scheduled)
		# else
		# Go to ClinicQueue.where(not scheduled)

		# Status 1 -> In Queue, Status 2 -> In Progress, Status 3 -> finished
		# Queue Type 1 -> Walkin, Queue Type 2 -> Scheduled
		# byebug
		if in_progress
			user_to_mail = in_progress.patient

			UserMailer.with(user: user_to_mail).finished_queue.deliver_now
			in_progress.update(status: 3)

			if clinic_queues.empty?
				in_progress.update(status: 3)
			end
		end

		next_for_schedule = clinic_queues.where(queue_type: 2).first

		# Check for current time
		# If there are any Appointments nga nalabyan na wala na serve,
		# Serve them next
		# else serve walk-in patients
		if next_for_schedule && DateTime.now >= next_for_schedule.schedule.asctime.in_time_zone("Hong Kong")
			user_to_mail = next_for_schedule.patient
			UserMailer.with(user: user_to_mail).finished_queue.deliver_now
			next_for_schedule.update(status: 2)
			in_progress = next_for_schedule
		else
			if next_for_queue = clinic_queues.where(queue_type: 1).first
				next_for_queue.update(status: 2)
				user_to_mail = next_for_queue.patient
				UserMailer.with(user: user_to_mail).turn_is_up.deliver_now
				in_progress = next_for_queue
			else
				if next_for_schedule && DateTime.now >= next_for_schedule.schedule.asctime.in_time_zone("Hong Kong")
					user_to_mail = next_for_schedule.patient
					UserMailer.with(user: user_to_mail).turn_is_up.deliver_now
					next_for_schedule.update(status: 2)
					in_progress = next_for_schedule
				end
			end
		end
    logger.info "!!!!!!ENDING!!!!!"
  end

	def clinic_queues
		@clinic_queues = ClinicQueue.queue_today.where(status: 1).order('queue_type DESC, schedule')
	end

	def in_progress
		@in_progress  = ClinicQueue.queue_today.where(status: 2).last
	end

  def logger
    @logger ||= Logger.new('log/automate-queue.log')
  end
end

