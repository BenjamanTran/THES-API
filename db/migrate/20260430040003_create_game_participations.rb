class CreateGameParticipations < ActiveRecord::Migration[8.0]
  def change
    create_table :game_participations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :team, default: 0, null: false
      t.string :position
      t.integer :score
      t.boolean :winner, default: false

      t.timestamps
    end

    add_index :game_participations, [ :user_id, :game_id ], unique: true
  end
end
