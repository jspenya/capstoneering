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
#  slots      :integer          default(15)
#
class ClinicSchedule < ApplicationRecord
  belongs_to :clinic
  has_many :clinic_special_cases, dependent: :destroy

  validates :day, uniqueness: { scope: :clinic, message: "already exists in this clinic." }

  validates :day, uniqueness: { message: "Schedule already exists in other clinic." }
end
