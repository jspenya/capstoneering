class AddPriorityNumberToAppointments < ActiveRecord::Migration[6.1]
  def change
    add_column :appointments, :priority_number, :integer
  end
end
