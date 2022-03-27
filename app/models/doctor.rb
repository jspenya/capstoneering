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
#
class Doctor < User
  has_many :appointments
  has_many :clinics

  def self.default_scope
    where(role: 2)
  end
end
