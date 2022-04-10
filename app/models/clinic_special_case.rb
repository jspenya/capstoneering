class ClinicSpecialCase < ApplicationRecord
  belongs_to :clinic_schedule

  validate :reject_past_dates, on: :create
  validate :only_on_clinic_day_schedule, on: :create

  def reject_past_dates
    if day < Date.today
      errors.add(:base, "Cannot add a special case in the past.")
    end
  end

  def only_on_clinic_day_schedule
    clinic_day = self.clinic_schedule.day
    unless clinic_day == day.strftime("%A")
      errors.add(:base, "Can only add special case on clinic day!")
    end
  end
end
