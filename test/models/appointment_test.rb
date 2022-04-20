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
require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
