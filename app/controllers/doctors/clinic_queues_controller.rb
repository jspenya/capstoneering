class Doctors::ClinicQueuesController < DoctorsController
  require 'csv'
	before_action :authenticate_user!
  # before_action :set_patient
  before_action :set_clinic
  before_action :set_clinic_queue
  before_action :set_in_progress, only: [:index, :start_queue, :next_patient]
	autocomplete :patient, :email

	def index
		# @clinics = Clinic.all
		@clinic_queues
		@patient  = Patient.new
		@patients = Patient.all
		# @in_progress = ClinicQueue.queue_today.where(status: 2).last
	end

	def queue_autocomplete_patient
    term = params[:term]
    terms = make_terms_from term

    patients = Patient.where(terms).all
    render :json => patients.map { |d| {:id => d.id, :label => d.fullname_and_email, :value => d.fullname_and_email} }
  end

	def make_terms_from term
    terms = term.split.map{|t| "lastname ilike '%%%s%%'" % t}.join(" or ")
  end

	def next_patient
		# Status 1 -> In Queue, Status 2 -> In Progress, Status 3 -> finished
		# Queue Type 1 -> Walkin, Queue Type 2 -> Scheduled
    @clinic_queues = @clinic_queues.where(skip_for_now: false)

		if @in_progress
			user_to_mail = @in_progress.patient

			# UserMailer.with(user: user_to_mail).finished_queue.deliver_now
      TwilioClient.new.send_text(@in_progress.patient, "Thank you for your visit, #{@in_progress.patient.firstname}. Be well.")
			@in_progress.update(status: 3)
		end

		next_for_schedule = @clinic_queues.where(queue_type: 2).first

		# Check for current time
		# If there are any Appointments nga nalabyan na wala na serve,
		# Serve them next
		# else serve walk-in patients
		if next_for_schedule # && Time.now.utc >= next_for_schedule.schedule
      user_to_mail = next_for_schedule.patient

			# UserMailer.with(user: user_to_mail).finished_queue.deliver_now
      TwilioClient.new.send_text(@in_progress.patient, "Thank you for your visit, #{@in_progress.patient.firstname}. Be well.")
      next_for_schedule.update(status: 2)
			@in_progress = next_for_schedule
		else
			if next_for_queue = @clinic_queues.where(queue_type: 1).first
				next_for_queue.update(status: 2)

				user_to_mail = next_for_queue.patient

				# UserMailer.with(user: user_to_mail).turn_is_up.deliver_now
        TwilioClient.new.send_text(next_for_queue.patient, "Hello #{next_for_queue.patient.firstname}, this is from Dr. Peña's clinic. The doctor is now ready to see you. Please proceed to the clinic and show the secretary this message.\n\nThank you for patiently waiting. Have a nice day!\n\n**This is an auto-generated message so please do not reply.**")
				@in_progress = next_for_queue
			else
				if next_for_schedule
					if @in_progress = next_for_schedule
						next_for_schedule.update(status: 3)
						# UserMailer.with(user: user_to_mail).finished_queue.deliver_now
            TwilioClient.new.send_text(@in_progress.patient, "Thank you for your visit, #{@in_progress.patient.firstname}. Be well.")
					# else
					# 	next_for_schedule.update(status: 2)
					#	UserMailer.with(user: user_to_mail).turn_is_up.deliver_now
					# 	@in_progress = next_for_schedule
					end
				end
			end
		end

		redirect_to doctor_clinic_queues_url

		# clinic_queue_to_be_finished = @clinic_queues.first
		# clinic_queue_to_be_finished.update(status: 3) # First in queue is finished

		# redirect_to doctor_clinic_queues_url

		# clinic_queue_to_be_in_progress = @clinic_queues.first
		# clinic_queue_to_be_in_progress.update(status: 2) # Second in queue is In Progress
	end

	def start_queue
		return if ClinicQueue.queue_today.present?
		qs = Appointment.doctor_appointments_today.to_a.map{|a| {user_id: a.user_id, clinic_id: a.clinic_id, schedule: a.schedule, queue_type: 2, status: 1} }

		ClinicQueue.create! qs

		# clinic_queues = @clinic_queues.pluck(:id)
		# in_progress = 1

		# set_worker_schedule(clinic_queues, in_progress)

		redirect_to doctor_clinic_queues_url, notice: "Started queue."
	end

  def delay_queue
    delay_time = params[:delay_time]
    clinic_queue_today = ClinicQueue.queue_today

    affected_clinic_queues = ClinicQueue.queue_today.where(status: 1)

    affected_clinic_queues.each do |cq|
      cq.schedule = cq.schedule + delay_time.to_i.minutes
      cq.save
      TwilioClient.new.send_text(cq.patient, delay_sms_template(cq.schedule))
    end

    redirect_to doctor_clinic_queues_path, notice: 'Queue successfully delayed.'
  end

  def delay_sms_template schedule
    "Due to unforseen circumstances, we regret to inform you that your appointment was rescheduled to #{schedule.strftime("%I:%M %p")} on #{schedule.strftime("%B %d, %Y")}. We apologize for the inconvenience.\n\nIf this schedule does not work for you, you may rebook your appointment.\n\nIn case of emergency and you needed immediate attention, you may visit your nearest emergency center.\n\n**This is an auto-generated message so please do not reply.**"
  end

  def cancel_todays_queue
    day_to_move = params[:day_to_move].to_date
    clinic_days = @clinic.clinic_schedules.pluck(:day)
    return redirect_to doctor_clinic_queues_path, alert: 'You cannot reschedule to a past date' if day_to_move < Date.today
    return redirect_to doctor_clinic_queues_path, alert: "There is no clinic for #{@clinic.name.split('_').join(" ")} on that day" unless clinic_days.include?(day_to_move.strftime("%A"))
    return redirect_to doctor_clinic_queues_path, alert: 'You cannot reschedule to today' if day_to_move == Date.today
    return redirect_to doctor_clinic_queues_path, alert: 'You cannot reschedule over 1 month' if day_to_move > Date.today + 30.days

    # Status: 2 are 'IN Progress'
    clinic_queue_today = ClinicQueue.queue_today.where(status: 1)

    clinic_schedule_day_to_move_to = day_to_move

    # clinic_queue_today.find_each do |cq|
    #   date_for_resched = Date.new(clinic_schedule_date_to_move_to.to_date.year, clinic_schedule_date_to_move_to.to_date.month, clinic_schedule_date_to_move_to.to_date.day)
    #   date_time_for_resched = DateTime.new(date_for_resched.year, date_for_resched.month, date_for_resched.day, cq.schedule.hour, cq.schedule.min)

    #   UserMailer.with(user: cq.patient, date: date_time_for_resched).queue_cancelled.deliver_now
    # end

    # Delete queue for the next day
    queue_for_next_day = ClinicQueue.where(schedule: clinic_schedule_day_to_move_to)
    queue_for_next_day.destroy_all

    # Delete queue for today
    clinic_queue_today.destroy_all

    # Rebuild the queue with alternating appointments
		# for_queue_next_day = Appointment
    #                       .where(schedule: clinic_schedule_date_to_move_to.beginning_of_day..clinic_schedule_date_to_move_to.end_of_day)
    #                       .order('schedule')

    appointments_of_day_scheduled = Appointment.where(schedule: clinic_schedule_day_to_move_to.beginning_of_day..clinic_schedule_day_to_move_to.end_of_day).order('schedule')

    # Update the appointment schedule sa next day
    # In order to squeeze today's appointments into this day
    # Add the clinic appointment duration minutes to each appointment
    # Except the first appointment on this day
    appointments_of_day_scheduled.to_a.drop(1)
                                              .each.with_index(1)
                                              .map{ |a, i|
                                                t = i * a.clinic.appointment_duration.minutes;
                                                a.update!(schedule: a.schedule + t + 5.seconds)
                                              }.unshift(*appointments_of_day_scheduled.to_a.first)

    # Update the appointment (today) schedules
    appointments_of_day_cancelled = Appointment.doctor_appointments_today
                                               .each.with_index(1)
                                               .map{ |a, i|
                                                  t = i * a.clinic.appointment_duration.minutes;

                                                  date_time_for_resched = DateTime.new(clinic_schedule_day_to_move_to.year, clinic_schedule_day_to_move_to.month, clinic_schedule_day_to_move_to.day, a.schedule.hour, a.schedule.min);

                                                  a.update(schedule: date_time_for_resched + t + 5.seconds)
                                                }

    # qs_next_day = for_queue_next_day.to_a.each_with_index.map{ |n, i| t = i * n.clinic.appointment_duration.minutes; { user_id: n.user_id, clinic_id: n.clinic_id, schedule: n.schedule + t, queue_type: 2, status: 1 } }
		# # This cancels all of the patients in today's Queue
    # qs_for_today = Appointment.doctor_appointments_today.to_a.drop(1).each_with_index.map{|a, i| t = i * a.clinic.appointment_duration.minutes; {user_id: a.user_id, clinic_id: a.clinic_id, schedule: a.schedule + t, queue_type: 2, status: 1} }

    # alternating_queue = qs_next_day.zip(qs_for_today).flatten.compact
    # # Queue (Alternating) for next day is built
    # queue_next_day = ClinicQueue.create! alternating_queue

		# queue_nextday_ids = clinic_queue_today.last.clinic.clinic_schedules.where.not(day: Date.today.strftime("%A")).first.clinic.clinic_queues.pluck(:id)

		# queue_next_day_ids = queue_next_day.pluck(:id)
		# HOW DO I MERGE THESE QUEUES ;;;;;;;
		# build_queue_for_next(queue_today_ids, queue_nextday_ids)

    # clinic_queue_today.find_each do |cq|
    #   date_for_resched = Date.new(clinic_schedule_date_to_move_to.to_date.year, clinic_schedule_date_to_move_to.to_date.month, clinic_schedule_date_to_move_to.to_date.day)
    #   date_time_for_resched = DateTime.new(date_for_resched.year, date_for_resched.month, date_for_resched.day, cq.schedule.hour, cq.schedule.min)

    #   cq.update(schedule: date_time_for_resched + 15.minutes)
    #   UserMailer.with(user: cq.patient, date: cq.schedule).queue_cancelled.deliver_now
    # end

    redirect_to doctor_clinic_queues_url, notice: "Queue was cancelled for today."
  end

  def toggle_skip_for_now
    clinic_queue = ClinicQueue.find(params[:id])

    if clinic_queue.skip_for_now?
      clinic_queue.update(skip_for_now: false)
      TwilioClient.new.send_text(clinic_queue.patient, "Hi #{clinic_queue.patient.firstname}. You have been added back to the queue. Please stand-sby for your turn.")
      redirect_to doctor_clinic_queues_path, notice: "#{clinic_queue.patient.fullname} is added back to the queue."
    else
      clinic_queue.update(skip_for_now: true)
      TwilioClient.new.send_text(clinic_queue.patient, "Hi #{clinic_queue.patient.firstname}. You are currently being skipped. Please proceed to the clinic to go on with your appointment.")
      redirect_to doctor_clinic_queues_path, notice: "#{clinic_queue.patient.fullname} is skipped for now."
    end
  end
	# def set_worker_schedule clinic_queues, in_progress
  #   Sidekiq.set_schedule(
  #     "auto_queue",
  #     {
  #       'cron' => "* * * * *", 'class' => "AutomateQueue",
  #       'args' => [{ clinic_queues: clinic_queues, in_progress: in_progress }]
  #     }
  #   )
  # end


	def create
		@patient = Patient.new(patient_params)
    if @patient.save
      @clinic_queue = ClinicQueue.create!(schedule: Time.now.utc, user_id: @patient.id)

      redirect_to doctor_queue_path, notice: "Patient created successfully!"
    else
      redirect_to patient_book_appointment_url, notice: "Patient not created!! #{@patient.errors.first.full_message}"
    end
	end

	def add_existing_patient_to_queue
		user_field = params[:patient][:email]
    f_name, l_name, email = user_field.split(" ")

    user = User.find_by(email: email)

		@clinic_queue = user.clinic_queues.new(clinic_id: @clinic.id, queue_type: 1, status: 1)

    if @clinic_queue.save
			# UserMailer.with(user: user).added_to_queue.deliver_now
      redirect_to doctor_clinic_queues_url, notice: "Patient added to queue successfully!"
    else
      redirect_to doctor_clinic_queues_url, alert: "There was a problem in adding patient to queue. #{@clinic_queue.errors.first.full_message}"
    end
	end

	def add_patient_to_queue
    @patient = Patient.new(
			firstname: params[:patient][:firstname],
			lastname: params[:patient][:lastname],
			mobile_number: params[:patient][:mobile_number],
			email: params[:patient][:email],
			password: params[:patient][:password],
			password_confirmation: params[:patient][:password_confirmation]
		)

    if @patient.save
			user = User.find(@patient.id)

      @clinic_queue = ClinicQueue.create!(user_id: user.id, clinic_id: @clinic.id, queue_type: 1, status: 1)
      redirect_to doctor_clinic_queues_url, notice: "Patient added to queue successfully!"
    else
      redirect_to doctor_clinic_queues_url, alert: "There was a problem in adding patient to queue. #{@clinic_queue.errors.first.full_message}"
    end
  end

	def destroy
		@clinic_queue = ClinicQueue.find(params[:id])
		@clinic_queue.destroy

		redirect_to doctor_clinic_queues_url, notice: "Successfully removed from queue!"
	end

  def export
    @queues = ClinicQueue.queue_today

    respond_to do |format|
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=#{Date.today.to_s}-queue.csv"
        render template: "/doctors/clinic_queues/export.csv.erb"
      end
    end
  end


	private
	def set_clinic
		clinic_id = ClinicSchedule.where(day: Date.today.strftime("%A"))&.first&.clinic_id

		@clinic = Clinic.find(clinic_id) if clinic_id
	end

	def set_clinic_queue
		@clinic_queues = ClinicQueue.queue_today.where(status: 1).order('queue_type DESC, schedule')
	end

	def set_in_progress
		# return nil if @clinic_queues.empty?
		@in_progress = ClinicQueue.queue_today.where(status: 2).last
	end

	def set_patient
	end

	def build_queue_for_next today_queue_ids, next_day_queue_ids
		today_queue_ids.zip(next_day_queue_ids).flatten.compact
	end
end
