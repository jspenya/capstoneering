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
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  attr_writer :login
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, authentication_keys: [:login]
  enum role: { patient: 1, doctor: 2, secretary: 3 }
  has_many :appointments, inverse_of: :user, dependent: :destroy
  has_many :clinics, dependent: :destroy
  has_many :clinic_queues, dependent: :destroy
  validates :mobile_number, uniqueness: true


  accepts_nested_attributes_for :appointments, :allow_destroy => true
  validates :mobile_number, phone: true

  def login
    @login || self.mobile_number || self.email
  end

  def email_required?
    false
  end

  def fullname
    @fullname ||= firstname.capitalize + " " + lastname.capitalize
  end

  def appointments_in_a_day datetime
    start_of_day = datetime.beginning_of_day
    end_of_day = datetime.end_of_day
    user_appointments = self.appointments.where("schedule >= ? and schedule <= ?", start_of_day, end_of_day)

    user_appointments.count
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["mobile_number = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:mobile_number) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end
end
