class AddSlotsToClinicSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :clinic_schedules, :slots, :integer, default: 15
  end
end
