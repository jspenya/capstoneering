# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  firstname              :string           default("")
#  lastname               :string           default("")
#  birthdate              :date
#  gender                 :string
#  role                   :integer          default("patient")
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  mobile_number          :string
#
class Patient < User
  has_many :appointments
  has_many :clinic_queues

  accepts_nested_attributes_for :appointments

	def self.default_scope
    where(role: 1)
  end

  scope :my_default_scope, ->(){ where(role: 1) }

  def fullname_and_email
    @fullname_and_email ||= " #{firstname} #{lastname} #{email} "
  end
end
