class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.datetime :played_at
      t.string :location
      t.integer :status, default: 0, null: false
      t.integer :match_type, default: 0, null: false

      t.timestamps
    end
  end
end
