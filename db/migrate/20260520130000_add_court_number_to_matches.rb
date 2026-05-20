# frozen_string_literal: true

class AddCourtNumberToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :court_number, :integer
    add_index :matches, %i[game_id court_number]
  end
end
