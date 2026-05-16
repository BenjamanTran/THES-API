# frozen_string_literal: true

class AddPlaceholderToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :placeholder, :boolean, default: false, null: false
    add_index :users, :placeholder
  end
end
