# frozen_string_literal: true

class RenameGenderAdjustmentToDesiredFemalePrice < ActiveRecord::Migration[8.1]
  def change
    remove_column :game_settlements, :gender_adjustment_steps, :integer, default: 0, null: false
    add_column :game_settlements, :desired_female_price, :integer, default: 0, null: false
  end
end
