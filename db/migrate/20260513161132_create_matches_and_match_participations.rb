# frozen_string_literal: true

class CreateMatchesAndMatchParticipations < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :match_number, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.integer :team_a_score
      t.integer :team_b_score
      t.string :winner_team
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end

    add_index :matches, %i[game_id match_number], unique: true

    create_table :match_participations do |t|
      t.references :match, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :team, null: false, default: 0
      t.boolean :winner, default: false
      t.timestamps
    end

    add_index :match_participations, %i[match_id user_id], unique: true
  end
end
