# frozen_string_literal: true

class CreateGamePlayerPairs < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :pair_policy, :integer, default: 0, null: false

    create_table :game_player_pairs do |t|
      t.references :game, null: false, foreign_key: true
      t.bigint :user_a_id, null: false
      t.bigint :user_b_id, null: false
      t.integer :status, default: 0, null: false
      t.bigint :created_by_id
      t.timestamps
    end

    add_index :game_player_pairs, %i[game_id user_a_id user_b_id], unique: true,
              name: 'index_game_player_pairs_on_game_and_users'
    add_index :game_player_pairs, %i[game_id user_a_id]
    add_index :game_player_pairs, %i[game_id user_b_id]
    add_foreign_key :game_player_pairs, :users, column: :user_a_id
    add_foreign_key :game_player_pairs, :users, column: :user_b_id
    add_foreign_key :game_player_pairs, :users, column: :created_by_id
  end
end
