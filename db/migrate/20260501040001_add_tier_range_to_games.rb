class AddTierRangeToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :min_tier, :integer, default: 0, null: false
    add_column :games, :max_tier, :integer, default: 0, null: false
  end
end
