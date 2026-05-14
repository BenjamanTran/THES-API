# frozen_string_literal: true

class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :district
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.string :mapbox_id
      t.references :created_by, foreign_key: { to_table: :users }, null: true
      t.boolean :verified, default: false, null: false
      t.timestamps
    end

    add_index :venues, %i[lat lng]
    add_index :venues, :city
    add_index :venues, :mapbox_id, unique: true
  end
end
