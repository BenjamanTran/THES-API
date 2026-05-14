# frozen_string_literal: true

class AddHostRatingToGameParticipations < ActiveRecord::Migration[8.1]
  def change
    add_column :game_participations, :host_rated_tier, :integer, null: true
    add_column :game_participations, :host_rated_stars, :integer, null: true
    add_column :game_participations, :host_rating_note, :string, limit: 200, null: true
  end
end
