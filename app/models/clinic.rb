# == Schema Information
#
# Table name: clinics
#
#  id                   :bigint           not null, primary key
#  user_id              :bigint           not null
#  name                 :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  start_time           :time
#  end_time             :time
#  appointment_duration :integer
#  room_number          :string
#  active               :boolean
#
class Clinic < ApplicationRecord
  belongs_to :user
  belongs_to :doctor, class_name: 'User', foreign_key: 'user_id'
  belongs_to :secretary, class_name: 'User', foreign_key: 'user_id'

  has_many :clinic_schedules, dependent: :destroy
  has_many :appointments #, dependent: :destroy
  has_many :clinic_queues #, dependent: :destroy

  accepts_nested_attributes_for :user, :doctor, :secretary, :appointments, :clinic_schedules
end
