# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
# require_relative '../lib/populator_fix.rb'
# require 'faker'

# User.populate 50 do |u|
#   u.firstname = Faker::Name.first_name
#   u.lastname = Faker::Name.unique.last_name
#   u.mobile_number = Faker::PhoneNumber.phone_number
#   u.email = Faker::Internet.email
#   u.gender = Faker::Gender.binary_type
#   u.encrypted_password = User.new(:password => 'testing 123').encrypted_password
#   u.role = 1
# end

User.create([
  { firstname: 'Doc', lastname: 'Vic', mobile_number: '9676514239', password: '123456', password_confirmation: '123456', role: 'doctor' },
  { firstname: 'Sec', lastname: 'Vangie', mobile_number: '9289185284', password: '123456', password_confirmation: '123456', role: 'secretary' },
  { firstname: 'Jose', lastname: 'Peña', mobile_number: '9973806704', password: '123456', password_confirmation: '123456' }
])
