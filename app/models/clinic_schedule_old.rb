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
end
