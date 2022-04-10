# == Schema Information
#
# Table name: clinic_schedules
#
#  id         :bigint           not null, primary key
#  day        :string
#  start_time :time
#  end_time   :time
#  clinic_id  :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ClinicSchedule < ApplicationRecord
  belongs_to :clinic
  has_many :clinic_special_cases
  
  validates :day, uniqueness: { scope: :clinic,
    message: "Clinic schedule cannot be within the same day." }
  
    validates :day, uniqueness: { message: "Schedule already exists in other clinic." }
end
