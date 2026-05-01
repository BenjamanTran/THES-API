class CreateSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :skills do |t|
      t.string :code, null: false

      t.timestamps
    end

    add_index :skills, :code, unique: true
  end
end
