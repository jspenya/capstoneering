# == Schema Information
#
# Table name: appointments
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  schedule   :datetime
#  status     :string
#  clinic_id  :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Appointment < ApplicationRecord
  belongs_to :user, inverse_of: :appointments
  belongs_to :patient, class_name: 'User', foreign_key: 'user_id'
  belongs_to :clinic
  # belongs_to :appointment_slot

  validates :schedule, uniqueness: { scope: :clinic }
  validate :only_one_appointment_in_a_day, on: :create
  validate :reject_past_dates, on: :create
  validate :only_on_clinic_day_schedule, on: :create
  validate :deny_patient_already_in_queue, on: :create

  accepts_nested_attributes_for :clinic

  scope :current_week, ->{
    start = Time.zone.now
    where(schedule: start.beginning_of_week..start.end_of_week)
  }

  # scope :clinic_days, -> {
  #   start = Time.zone.now
  #   range = start.beginning_of_week..start.end_of_month

  #   range.delete_if! { |day| day == day.saturday? || day.sunday? }
  #   where(schedule: )
  # }

  scope :doctor_appointments_today, -> {
    where(schedule: DateTime.now.beginning_of_day..DateTime.now.end_of_day)
  }

  scope :current_month, -> {
    where(schedule: DateTime.now.beginning_of_month..DateTime.now.end_of_month)
  }

  scope :upcoming_appointments_today, -> {
    start = DateTime.now
    where(schedule: start..start.end_of_day )
  }

  def only_one_appointment_in_a_day
    if user.appointments_in_a_day(schedule) >= 1
      errors.add(:base, "Patient cannot have more than 1 appointment a day.")
    end
  end

  def reject_past_dates
    if schedule < DateTime.now
      errors.add(:base, "Cannot book an appointment in the past.")
    end
  end

  def only_on_clinic_day_schedule
    byebug
    clinic_days = self.clinic.clinic_schedules.pluck(:day)
    unless clinic_days.include?(schedule.strftime("%A"))
      errors.add(:base, "Can only book an appointment on clinic day!")
    end
  end

  def only_on_clinic_schedules
    if schedule > self.clinic.clinic_schedules
    end
  end

  def patient_no_same_day_rescheduling
    if user.patient?
      return unless schedule < DateTime.now.end_of_day && schedule > DateTime.now.beginning_of_day
      return unless scheduled_changed?

      errors.add(:name, 'Patient cannot reschedule within the day.')
    end
  end

  def only_set_appointments_1_month
    if schedule > (DateTime.now + 30.days)
      errors.add(:name, 'Patient cannot set an appointment over a month.')
    end
  end

  def deny_patient_already_in_queue
    if ClinicQueue.queue_today.pluck(:user_id).include? self.user_id
      errors.add(:Error, ' : Patient is already in queue.')
    end
  end
end
