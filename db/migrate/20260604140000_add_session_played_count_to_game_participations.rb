# frozen_string_literal: true

class AddSessionPlayedCountToGameParticipations < ActiveRecord::Migration[8.1]
  def change
    return if column_exists?(:game_participations, :session_played_count)

    add_column :game_participations, :session_played_count, :integer, default: 0, null: false
  end
end
