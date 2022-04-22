require 'sidekiq-scheduler'

class AppointmentsTodayNotificationWorker
  include Sidekiq::Worker

  def perform
    return unless Appointment.doctor_appointments_today.any?
    logger.info "!!!!!!STARTING!!!!!"
    
    Appointment.doctor_appointments_today.find_each do |a|
      @user = a.user
      @clinic = a.clinic
      @schedule = a.schedule
      TwilioClient.new.send_text(@user, message)
    end

    logger.info "!!!!!!ENDING!!!!!"
  end

  def logger
    @logger ||= Logger.new('log/appointments-today-notif-queue.log')
  end
  
  def message
    "
    Hi #{@user.firstname}, this is from the clinic. This is a friendly reminder of your upcoming appointment today at #{@clinic.name.split("_").join(" ")} at #{@schedule.strftime("%I:%M %p")}.\n\nYou will receive updates through the mobile phone number you have provided regarding your queue status. To maintain social distancing and to provide you with more convenience, please keep yourself posted on when we are ready to receive you at the clinic today.\n\nSee you, and have a great day!\n\n**Do not reply. This is an auto-generated message.**
    "
  end
end

