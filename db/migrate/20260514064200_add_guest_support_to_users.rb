# frozen_string_literal: true

class AddGuestSupportToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :guest, :boolean, default: false, null: false
    change_column_null :users, :email, true
  end
end
