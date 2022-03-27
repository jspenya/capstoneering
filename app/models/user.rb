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
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  enum role: { patient: 1, doctor: 2, secretary: 3 }
  has_many :appointments, inverse_of: :user, dependent: :destroy
  has_many :clinics, dependent: :destroy
  accepts_nested_attributes_for :appointments, :allow_destroy => true

  def fullname
    @fullname ||= firstname + " " + lastname
  end

  def appointments_in_a_day datetime
    start_of_day = datetime.beginning_of_day
    end_of_day = datetime.end_of_day
    user_appointments = self.appointments.where("schedule >= ? and schedule <= ?", start_of_day, end_of_day)

    user_appointments.count
  end
end
