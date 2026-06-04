# frozen_string_literal: true

class AddArrivedAtCourtToGameParticipations < ActiveRecord::Migration[8.1]
  def change
    return if column_exists?(:game_participations, :arrived_at_court)

    add_column :game_participations, :arrived_at_court, :boolean, default: false, null: false
  end
end
