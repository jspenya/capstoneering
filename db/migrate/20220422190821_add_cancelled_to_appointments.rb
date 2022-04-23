class AddCancelledToAppointments < ActiveRecord::Migration[6.1]
  def change
    add_column :appointments, :cancelled, :boolean, default: false
  end
end
