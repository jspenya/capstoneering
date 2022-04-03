class AddTypeToClinicQueues < ActiveRecord::Migration[6.1]
  def change
    add_column :clinic_queues, :type, :integer
  end
end
