# frozen_string_literal: true

class AddDeclaredToRanks < ActiveRecord::Migration[8.1]
  def change
    add_column :ranks, :declared_rating, :integer, if_not_exists: true
    add_column :ranks, :declared_tier, :integer, if_not_exists: true
  end
end
