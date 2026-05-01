class AddGameFlowColumnsToGames < ActiveRecord::Migration[8.1]
  def change
    change_table :games do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.integer :max_players, null: false, default: 2
      t.integer :players_count, null: false, default: 0
      t.references :host, null: true, foreign_key: { to_table: :users }
    end

    remove_column :games, :played_at, :datetime
  end
end
