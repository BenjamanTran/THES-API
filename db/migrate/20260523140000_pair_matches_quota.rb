# frozen_string_literal: true

class PairMatchesQuota < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :pair_matches_limit, :integer
    add_column :games, :pair_matches_used, :integer, default: 0, null: false
    remove_column :games, :pair_policy, :integer
  end
end
