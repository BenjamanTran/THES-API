# frozen_string_literal: true

class AddGameListingIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :games, :start_time
    add_index :games, :status
    add_index :games, %i[min_tier max_tier]
  end
end
