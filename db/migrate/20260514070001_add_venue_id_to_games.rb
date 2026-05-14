# frozen_string_literal: true

class AddVenueIdToGames < ActiveRecord::Migration[8.1]
  def change
    add_reference :games, :venue, null: true, foreign_key: true
  end
end
