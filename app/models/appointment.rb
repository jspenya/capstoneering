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
  scope :upcoming_appointments_today, -> {
    start = DateTime.now
    where(schedule: start..start.end_of_day )
  }

  def only_one_appointment_in_a_day
    if user.appointments_in_a_day(schedule) >= 1
      errors.add(:base, "Patient cannot have more than 1 appointment a day.")
    end
  end
end
