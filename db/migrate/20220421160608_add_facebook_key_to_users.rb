class AddFacebookKeyToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :facebook_key, :string
  end
end
