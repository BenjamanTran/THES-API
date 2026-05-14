# frozen_string_literal: true

class AddMatchesCountToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :matches_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE games SET matches_count = (
            SELECT COUNT(*) FROM matches WHERE matches.game_id = games.id
          )
        SQL
      end
    end
  end
end
