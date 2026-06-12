# frozen_string_literal: true

class DropLegacySettlementColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :game_settlements, :expense_lines, :json
    remove_column :game_settlements, :mode, :integer, default: 0, null: false
    remove_column :game_settlements, :desired_female_price, :integer, default: 0, null: false
    remove_column :game_settlements, :fixed_male_price, :integer, default: 0, null: false
    remove_column :game_settlements, :fixed_female_price, :integer, default: 0, null: false
  end
end
