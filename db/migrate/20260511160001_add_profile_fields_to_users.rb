class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :gender, :integer, default: 0, null: false
    add_column :users, :phone, :string
  end
end
