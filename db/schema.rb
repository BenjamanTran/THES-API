# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_02_130001) do
  create_table "game_participations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.string "position"
    t.integer "score"
    t.integer "team", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "winner", default: false
    t.index ["game_id"], name: "index_game_participations_on_game_id"
    t.index ["user_id", "game_id"], name: "index_game_participations_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_game_participations_on_user_id"
  end

  create_table "games", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_time"
    t.bigint "host_id"
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.string "location"
    t.integer "match_type", default: 0, null: false
    t.integer "max_players", default: 2, null: false
    t.integer "max_tier", default: 5, null: false
    t.integer "min_tier", default: 0, null: false
    t.integer "players_count", default: 0, null: false
    t.datetime "start_time"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_games_on_host_id"
    t.index ["min_tier", "max_tier"], name: "index_games_on_min_tier_and_max_tier"
    t.index ["start_time"], name: "index_games_on_start_time"
    t.index ["status"], name: "index_games_on_status"
  end

  create_table "ranks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "division", default: 3
    t.datetime "last_played_at"
    t.integer "losses", default: 0, null: false
    t.integer "matches_count", default: 0, null: false
    t.integer "rating", default: 0, null: false
    t.integer "tier", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "wins", default: 0, null: false
    t.index ["rating"], name: "index_ranks_on_rating"
    t.index ["user_id"], name: "index_ranks_on_user_id", unique: true
  end

  create_table "user_skills", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level", default: 1, null: false
    t.string "skill_code", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "skill_code"], name: "index_user_skills_on_user_id_and_skill_code", unique: true
    t.index ["user_id"], name: "index_user_skills_on_user_id"
    t.index ["user_id"], name: "index_user_skills_on_user_id_and_skill_id", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "game_participations", "games"
  add_foreign_key "game_participations", "users"
  add_foreign_key "games", "users", column: "host_id"
  add_foreign_key "ranks", "users"
  add_foreign_key "user_skills", "users"
end
