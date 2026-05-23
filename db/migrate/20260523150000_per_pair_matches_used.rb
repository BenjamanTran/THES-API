# frozen_string_literal: true

class PerPairMatchesUsed < ActiveRecord::Migration[8.1]
  def change
    add_column :game_player_pairs, :matches_used, :integer, default: 0, null: false
    remove_column :games, :pair_matches_used, :integer
  end
end
