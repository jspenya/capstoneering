# == Schema Information
#
# Table name: clinic_special_cases
#
#  id                 :bigint           not null, primary key
#  day                :date
#  start_time         :datetime
#  end_time           :datetime
#  reason             :string
#  clinic_schedule_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  slots              :integer
#
require "test_helper"

class ClinicSpecialCaseTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
