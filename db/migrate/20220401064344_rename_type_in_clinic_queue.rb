class RenameTypeInClinicQueue < ActiveRecord::Migration[6.1]
  def change
    rename_column :clinic_queues, :type, :queue_type
  end
end
