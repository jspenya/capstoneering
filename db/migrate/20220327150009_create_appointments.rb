class CreateAppointments < ActiveRecord::Migration[6.1]
  def change
    create_table :appointments do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :schedule
      t.string :status
      t.references :clinic, null: false, foreign_key: true

      t.timestamps
    end
  end
end
