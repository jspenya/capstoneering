class AddSkipForNowToClinicQueues < ActiveRecord::Migration[6.1]
  def change
    add_column :clinic_queues, :skip_for_now, :boolean, default: false
  end
end
