class AddPriceRangeToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :min_price, :integer, default: 0, null: false
    add_column :games, :max_price, :integer, default: 0, null: false
    add_index :games, :min_price
  end
end
