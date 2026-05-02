# frozen_string_literal: true

class AddDescriptionToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :description, :text
  end
end
