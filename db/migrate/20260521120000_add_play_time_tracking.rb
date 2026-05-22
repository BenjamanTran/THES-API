# frozen_string_literal: true

class AddPlayTimeTracking < ActiveRecord::Migration[8.1]
  def change
    add_column :ranks, :play_time_seconds, :integer, default: 0, null: false
    add_column :game_participations, :play_time_credited, :boolean, default: false, null: false
  end
end
