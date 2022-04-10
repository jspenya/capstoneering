class AddSlotsToClinicSpecialCases < ActiveRecord::Migration[6.1]
  def change
    add_column :clinic_special_cases, :slots, :integer
  end
end
