# frozen_string_literal: true

class ChangeComputedStarsToDecimal < ActiveRecord::Migration[8.1]
  def change
    change_column :user_skill_snapshots, :computed_stars, :decimal, precision: 3, scale: 2, null: false, default: 1.0
  end
end
