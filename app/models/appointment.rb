# == Schema Information
#
# Table name: appointments
#
#  id              :bigint           not null, primary key
#  user_id         :bigint           not null
#  schedule        :datetime
#  status          :string
#  clinic_id       :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  priority_number :integer
#
class Appointment < ApplicationRecord
  include ActiveModel::Dirty
  belongs_to :user, inverse_of: :appointments
  belongs_to :patient, class_name: 'User', foreign_key: 'user_id'
  belongs_to :clinic
  # belongs_to :appointment_slot

  validates :schedule, uniqueness: { scope: :clinic }
  validate :only_one_appointment_in_a_day, on: :create
  validate :reject_past_dates, on: :create
  validate :check_special_case, on: :create
  validate :only_on_clinic_day_schedule, on: :create
  validate :deny_patient_already_in_queue, on: :create
  validate :patient_no_same_day_rescheduling, on: :update

  # after_create :send_appointment_creation_mail
  # after_update :send_appointment_reschedule_mail
  after_create :send_appointment_creation_sms
  after_update :send_appointment_reschedule_sms

  accepts_nested_attributes_for :clinic

  scope :current_week, ->{
    start = Time.now.asctime.to_date
    where(schedule: DateTime.now.beginning_of_week..DateTime.now.end_of_week)
  }

  # scope :clinic_days, -> {
  #   start = Time.zone.now
  #   range = start.beginning_of_week..start.end_of_month

  #   range.delete_if! { |day| day == day.saturday? || day.sunday? }
  #   where(schedule: )
  # }

  scope :doctor_appointments_today, -> {
    where(schedule: Time.now.asctime.to_date.beginning_of_day..Time.now.asctime.to_date.end_of_day).where(cancelled: false)
  }

  scope :current_month, -> {
    where(schedule: DateTime.now.beginning_of_month..DateTime.now.end_of_month.next_month).where(cancelled: false)
  }

  scope :upcoming_appointments_today, -> {
    start = DateTime.now.utc
    where(schedule: start..start.end_of_day ).where(cancelled: false)
  }

  scope :upcoming, -> {
    start = DateTime.now
    where(schedule: start..start.end_of_month.next_month).where(cancelled: false)
  }

  scope :appointments_on_this_day, -> (date) {
    where(schedule: date.beginning_of_day..date.end_of_day).where(cancelled: false).count
  }

  def only_one_appointment_in_a_day
    if user.appointments_in_a_day(schedule) >= 1
      errors.add(:base, "Patient cannot have more than 1 appointment a day.")
    end
  end

  def reject_past_dates
    if schedule.asctime.in_time_zone('Hong Kong') < DateTime.now
      errors.add(:base, "Cannot book an appointment in the past.")
    end
  end

  def only_on_clinic_day_schedule
    clinic_days = self.clinic.clinic_schedules.pluck(:day)
    unless clinic_days.include?(schedule.strftime("%A"))
      errors.add(:base, "Can only book an appointment on a clinic day")
    end
  end

  def only_on_clinic_schedules
    if schedule > self.clinic.clinic_schedules
    end
  end

  def patient_no_same_day_rescheduling
    if user.patient?
      return unless schedule < Time.now.utc.end_of_day && schedule > Time.now.utc.beginning_of_day
      return unless schedule_changed?

      errors.add(:user, 'cannot reschedule within the day.')
    end
  end

  def only_set_appointments_1_month
    if schedule > (Time.now.utc + 30.days)
      errors.add(:name, 'Patient cannot set an appointment over a month.')
    end
  end

  def deny_patient_already_in_queue
    return if schedule > Time.now.utc.end_of_day
    if ClinicQueue.queue_today.pluck(:user_id).include? self.user_id
      errors.add(:Error, ' : Patient is already in queue.')
    end
  end

  def check_special_case
    special_case = ClinicSpecialCase.find_by(day: schedule.to_date)
    return unless special_case.present?

    if Appointment.where(schedule: special_case.day.beginning_of_day..special_case.day.end_of_day).count > special_case.slots
      errors.add(:slots, "are full for this day.")
    end
  end

  def send_appointment_creation_mail
    return unless self.user.email.present?
    UserMailer.with(user: self.user).appointment_created.deliver_now
  end

  def send_appointment_creation_sms
    # TwilioClient.new.send_text(self.user, appointment_creation_sms_text)
  end

  def send_appointment_reschedule_mail
    return unless self.user.email.present?
    UserMailer.with(user: self.user, schedule: self.schedule).reschedule_notice.deliver_now
  end

  def send_appointment_reschedule_sms
    return unless saved_change_to_schedule?
    return unless self.user.mobile_number.present?
    # TwilioClient.new.send_text(self.user, appointment_reschedule_sms_text)
  end

  def appointment_creation_sms_text
    "Hi #{self.user.firstname? ? self.user.firstname : self.user.lastname}! Your appointment request for #{self.schedule.strftime("%B %d, %A")} at #{self.schedule.strftime("%I:%M %p")} is confirmed.\n\nYou will receive updates through the mobile phone number you have provided regarding your queue status on the day of your appointment. In any case that you need to reschedule or cancel your appointment, please access the link below.\n\nhttps://webdass-staging.herokuapp.com\n\n**This is an auto-generated message so please do not reply.**"
  end

  def appointment_reschedule_sms_text
    "Hi #{self.user.firstname}! Your appointment was rescheduled to #{self.schedule.strftime("%B %d, %A")}. We're very sorry for the inconvenience this has caused you.\n\nYou will receive updates through the mobile phone number you have provided regarding your queue status on the day of your appointment. In any case that you need to reschedule or cancel your appointment, please access the link below.\n\nhttps://webdass-staging.herokuapp.com/users/sign_in.\n\nThank you and be safe!\n\nThis is an automated message. Please do not reply to this number."
  end
end
