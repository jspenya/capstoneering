# == Schema Information
#
# Table name: users
#
#  id                                     :bigint           not null, primary key
#  email                                  :string           default("")
#  encrypted_password                     :string           default(""), not null
#  firstname                              :string           default("")
#  lastname                               :string           default("")
#  birthdate                              :date
#  gender                                 :string
#  role                                   :integer          default("patient")
#  reset_password_token                   :string
#  reset_password_sent_at                 :datetime
#  remember_created_at                    :datetime
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  mobile_number                          :string           not null
#  doctor_clinic_notification_time_buffer :integer          default(10)
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
