# frozen_string_literal: true

class AddPriorityToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :priority, :boolean, default: false, null: false
    add_index :matches, %i[game_id priority]
  end
end
