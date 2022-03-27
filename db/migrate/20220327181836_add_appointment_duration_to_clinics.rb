class AddAppointmentDurationToClinics < ActiveRecord::Migration[6.1]
  def change
    add_column :clinics, :appointment_duration, :integer
  end
end
