# == Schema Information
#
# Table name: clinic_queues
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  schedule   :datetime
#
require "test_helper"

class ClinicQueueTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
