class AddRoomNumberStatusToClinics < ActiveRecord::Migration[6.1]
  def change
    add_column :clinics, :room_number, :string
    add_column :clinics, :active, :boolean
  end
end
