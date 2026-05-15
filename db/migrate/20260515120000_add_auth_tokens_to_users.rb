# frozen_string_literal: true

class AddAuthTokensToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.datetime :email_verified_at
      t.string :password_reset_digest
      t.datetime :password_reset_sent_at
      t.string :email_verification_digest
      t.datetime :email_verification_sent_at
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE users SET email_verified_at = created_at WHERE guest = FALSE AND email_verified_at IS NULL
        SQL
      end
    end
  end
end
