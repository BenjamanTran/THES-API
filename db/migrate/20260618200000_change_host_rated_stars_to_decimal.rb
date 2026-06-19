# frozen_string_literal: true

class ChangeHostRatedStarsToDecimal < ActiveRecord::Migration[8.1]
  def change
    change_column :game_participations, :host_rated_stars, :decimal, precision: 3, scale: 2
  end
end
