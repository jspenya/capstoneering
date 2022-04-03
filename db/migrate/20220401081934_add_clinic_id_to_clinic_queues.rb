class AddClinicIdToClinicQueues < ActiveRecord::Migration[6.1]
  def change
    add_reference :clinic_queues, :clinic, null: false, foreign_key: true
  end
end
