class CreateUserSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :user_skills do |t|
      t.references :user, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :level, default: 1, null: false

      t.timestamps
    end

    add_index :user_skills, [ :user_id, :skill_id ], unique: true
  end
end
