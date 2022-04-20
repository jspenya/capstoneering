# == Schema Information
#
# Table name: clinic_queues
#
#  id           :bigint           not null, primary key
#  user_id      :bigint
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  schedule     :datetime
#  queue_type   :integer
#  clinic_id    :bigint           not null
#  status       :integer
#  skip_for_now :boolean          default(FALSE)
#
require "test_helper"

class ClinicQueueTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
