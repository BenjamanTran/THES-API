class RemoveSkillsTableAndUseSkillCode < ActiveRecord::Migration[8.0]
  def change
    remove_reference :user_skills, :skill, foreign_key: true
    add_column :user_skills, :skill_code, :string, null: false
    add_index :user_skills, [:user_id, :skill_code], unique: true

    drop_table :skills do |t|
      t.string :code, null: false
      t.timestamps
    end
  end
end
