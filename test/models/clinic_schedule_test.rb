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
require "test_helper"

class ClinicScheduleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
