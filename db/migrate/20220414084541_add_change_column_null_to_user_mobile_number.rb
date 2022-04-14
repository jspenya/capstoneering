class AddChangeColumnNullToUserMobileNumber < ActiveRecord::Migration[6.1]
  def self.up
    change_column :users, :mobile_number, :string, :null => false
  end

  def self.down
    change_column :users, :mobile_number, :string, :null => true
  end
end
