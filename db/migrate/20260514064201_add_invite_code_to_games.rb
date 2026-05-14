# frozen_string_literal: true

class AddInviteCodeToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :invite_code, :string, limit: 12
    add_index :games, :invite_code, unique: true
  end
end
