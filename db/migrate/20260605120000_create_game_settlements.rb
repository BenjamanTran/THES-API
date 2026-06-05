# frozen_string_literal: true

class CreateGameSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :game_settlements do |t|
      t.references :game, null: false, foreign_key: true, index: { unique: true }
      t.integer :mode, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.json :expense_lines, null: false
      t.integer :gender_adjustment_steps, null: false, default: 0
      t.integer :fixed_male_price, null: false, default: 0
      t.integer :fixed_female_price, null: false, default: 0
      t.datetime :published_at
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
