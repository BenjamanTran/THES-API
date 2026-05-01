class CreateRanks < ActiveRecord::Migration[8.0]
  def change
    create_table :ranks do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :rating, default: 0, null: false
      t.integer :tier, default: 0, null: false
      t.integer :division, default: 3
      t.integer :wins, default: 0, null: false
      t.integer :losses, default: 0, null: false
      t.integer :matches_count, default: 0, null: false
      t.datetime :last_played_at

      t.timestamps
    end

    add_index :ranks, :rating
  end
end
