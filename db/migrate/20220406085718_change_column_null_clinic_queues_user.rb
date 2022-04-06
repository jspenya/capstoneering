class ChangeColumnNullClinicQueuesUser < ActiveRecord::Migration[6.1]
  def change
    change_column_null :clinic_queues, :user_id, true
  end
end
