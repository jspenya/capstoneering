class AddDoctorClinicNotificationTimeBufferToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :doctor_clinic_notification_time_buffer, :integer, default: 10
  end
end
