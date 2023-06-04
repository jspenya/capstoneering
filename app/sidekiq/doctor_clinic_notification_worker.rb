require 'sidekiq-scheduler'

class DoctorClinicNotificationWorker
  include Sidekiq::Worker

  def perform
    logger.info "!!!!!!STARTING!!!!!"
    # byebug
    if clinic_schedule = ClinicSchedule.find_by(day: Date.today.strftime("%A"))
      if ClinicSchedule.find_by(day: Date.today.strftime("%A")).start_time.strftime("%I:%M:%S %p") == Doctor.first.doctor_clinic_notification_time_buffer.minutes.from_now.localtime.strftime("%I:%M:%S %p")
        # UserMailer.with(buffer_minutes: Doctor.first.doctor_clinic_notification_time_buffer).doc_clinic_time.deliver_now
        # logger.info "!!!!!!SENT MAIL!!!!!"
        # TwilioClient.new.send_text(Doctor.first, "Hi Doc, you have clinic in #{Doctor.first.doctor_clinic_notification_time_buffer} minutes at #{ClinicSchedule.find_by(day: Date.today.strftime("%A")).clinic.name.split("_").join(" ")}")
        logger.info "!!!!!!SENT TEXT!!!!!"
      end
    end

    logger.info "!!!!!!ENDING!!!!!"
  end

  def logger
    @logger ||= Logger.new('log/doctor-clinic-notif-queue.log')
  end
end

