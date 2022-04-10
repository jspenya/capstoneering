class CreateClinicSpecialCases < ActiveRecord::Migration[6.1]
  def change
    create_table :clinic_special_cases do |t|
      t.date :day
      t.datetime :start_time
      t.datetime :end_time
      t.string :reason
      t.belongs_to :clinic_schedule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
