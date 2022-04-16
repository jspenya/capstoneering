# == Schema Information
#
# Table name: clinic_queues
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  schedule   :datetime
#  queue_type :integer
#  clinic_id  :bigint           not null
#  status     :integer
#
class ClinicQueue < ApplicationRecord
  belongs_to :patient, class_name: 'User', foreign_key: 'user_id'
  belongs_to :clinic
  validates :user_id, uniqueness: true

  enum queue_type: { walkin: 1, scheduled: 2 }
  enum status: { in_queue: 1, in_progress: 2, finished: 3 }

  scope :queue_today, -> {
    where(schedule: Time.now.utc.beginning_of_day..Time.now.utc.end_of_day)
  }
end
