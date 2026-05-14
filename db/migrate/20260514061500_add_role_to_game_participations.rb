# frozen_string_literal: true

class AddRoleToGameParticipations < ActiveRecord::Migration[8.1]
  def change
    add_column :game_participations, :role, :integer, default: 0, null: false
  end
end
