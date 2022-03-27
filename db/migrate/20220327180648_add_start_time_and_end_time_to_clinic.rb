class AddStartTimeAndEndTimeToClinic < ActiveRecord::Migration[6.1]
  def change
    add_column :clinics, :start_time, :time
    add_index :clinics, :start_time

    add_column :clinics, :end_time, :time
    add_index :clinics, :end_time
  end
end
