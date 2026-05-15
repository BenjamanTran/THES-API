# frozen_string_literal: true

class AddSessionActiveAtToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :session_active_at, :datetime

    execute <<~SQL.squish
      UPDATE users
      SET session_active_at = updated_at
      WHERE session_token IS NOT NULL AND session_token != ''
    SQL
  end

  def down
    remove_column :users, :session_active_at
  end
end
