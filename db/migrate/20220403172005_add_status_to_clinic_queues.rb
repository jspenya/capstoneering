class AddStatusToClinicQueues < ActiveRecord::Migration[6.1]
  def change
    add_column :clinic_queues, :status, :integer
  end
end
