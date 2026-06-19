# frozen_string_literal: true

class ReplaceSkillSnapshotAxes < ActiveRecord::Migration[8.1]
  def change
    change_table :user_skill_snapshots, bulk: true do |t|
      t.integer :defense, null: false, default: 5
      t.integer :agility, null: false, default: 5
      t.integer :footwork, null: false, default: 5
      t.integer :stamina, null: false, default: 5

      t.remove :serve_receive, :rear_court, :net_play, :drive_counter, :defense_movement
    end
  end
end
