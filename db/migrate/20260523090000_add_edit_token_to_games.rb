# frozen_string_literal: true

class AddEditTokenToGames < ActiveRecord::Migration[8.1]
  def change
    return if column_exists?(:games, :edit_token)

    add_column :games, :edit_token, :string, limit: 64
    add_index :games, :edit_token, unique: true
  end
end
