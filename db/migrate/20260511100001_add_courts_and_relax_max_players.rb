class AddCourtsAndRelaxMaxPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :courts, :json
  end
end
