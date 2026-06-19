# frozen_string_literal: true

class AddDeclaredFieldsToUserSkillSnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :user_skill_snapshots, :declared_tier, :integer, null: false, default: 0
    add_column :user_skill_snapshots, :computed_stars, :integer, null: false, default: 1
    add_column :user_skill_snapshots, :declared_rating, :integer, null: false, default: 0
  end
end
