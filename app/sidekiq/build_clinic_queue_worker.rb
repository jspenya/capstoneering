require 'sidekiq-scheduler'

class BuildClinicQueueWorker
  include Sidekiq::Worker

  def perform
    logger.info "!!!!!!STARTING!!!!!"
    # byebug
    if clinic_schedule = ClinicSchedule.find_by(day: Date.today.strftime("%A"))
      if ClinicSchedule.find_by(day: Date.today.strftime("%A")).start_time.strftime("%I:%M:%S %p") == 30.minutes.from_now.localtime.strftime("%I:%M:%S %p")
        ClinicQueue.destroy_all
        qs = Appointment.doctor_appointments_today.to_a.map{|a| {user_id: a.user_id, clinic_id: a.clinic_id, schedule: a.schedule, queue_type: 2, status: 1} }

        ClinicQueue.create! qs
        logger.info "!!!!!!BUILT QUEUE!!!!!"
      end
    end

    logger.info "!!!!!!ENDING!!!!!"
  end

  def logger
    @logger ||= Logger.new('log/build-clinic-queue.log')
  end
end

