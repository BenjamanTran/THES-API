# frozen_string_literal: true

class CreateUserSkillSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :user_skill_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month, null: false
      t.integer :serve_receive, null: false
      t.integer :rear_court, null: false
      t.integer :attack, null: false
      t.integer :net_play, null: false
      t.integer :drive_counter, null: false
      t.integer :defense_movement, null: false
      t.decimal :overall_score, precision: 3, scale: 1, null: false

      t.timestamps
    end

    add_index :user_skill_snapshots, %i[user_id month], unique: true
  end
end
