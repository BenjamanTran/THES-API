# frozen_string_literal: true

class AddTitleToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :title, :string, limit: 100, null: true
  end
end
