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

ActiveRecord::Schema[8.1].define(version: 2026_06_19_090000) do
  create_table "game_participations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "arrived_at_court", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.decimal "host_rated_stars", precision: 3, scale: 2
    t.integer "host_rated_tier"
    t.string "host_rating_note", limit: 200
    t.boolean "play_time_credited", default: false, null: false
    t.string "position"
    t.integer "role", default: 0, null: false
    t.integer "score"
    t.integer "session_played_count", default: 0, null: false
    t.integer "team", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "winner", default: false
    t.index ["game_id"], name: "index_game_participations_on_game_id"
    t.index ["user_id", "game_id"], name: "index_game_participations_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_game_participations_on_user_id"
  end

  create_table "game_player_pairs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "game_id", null: false
    t.integer "matches_used", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_a_id", null: false
    t.bigint "user_b_id", null: false
    t.index ["created_by_id"], name: "fk_rails_96dc2aee27"
    t.index ["game_id", "user_a_id", "user_b_id"], name: "index_game_player_pairs_on_game_and_users", unique: true
    t.index ["game_id", "user_a_id"], name: "index_game_player_pairs_on_game_id_and_user_a_id"
    t.index ["game_id", "user_b_id"], name: "index_game_player_pairs_on_game_id_and_user_b_id"
    t.index ["game_id"], name: "index_game_player_pairs_on_game_id"
    t.index ["user_a_id"], name: "fk_rails_bece239702"
    t.index ["user_b_id"], name: "fk_rails_e3968ff0b3"
  end

  create_table "game_settlements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.datetime "published_at"
    t.json "sections"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["game_id"], name: "index_game_settlements_on_game_id", unique: true
    t.index ["updated_by_id"], name: "index_game_settlements_on_updated_by_id"
  end

  create_table "games", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.json "courts"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "edit_token", limit: 64
    t.datetime "end_time"
    t.bigint "host_id"
    t.string "invite_code", limit: 12
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.string "location"
    t.integer "match_type", default: 0, null: false
    t.integer "matches_count", default: 0, null: false
    t.integer "max_players", default: 2, null: false
    t.integer "max_price", default: 0, null: false
    t.integer "max_tier", default: 0, null: false
    t.integer "min_price", default: 0, null: false
    t.integer "min_tier", default: 0, null: false
    t.integer "pair_matches_limit"
    t.integer "players_count", default: 0, null: false
    t.datetime "start_time"
    t.integer "status", default: 0, null: false
    t.string "title", limit: 100
    t.datetime "updated_at", null: false
    t.bigint "venue_id"
    t.index ["edit_token"], name: "index_games_on_edit_token", unique: true
    t.index ["host_id"], name: "index_games_on_host_id"
    t.index ["invite_code"], name: "index_games_on_invite_code", unique: true
    t.index ["min_price"], name: "index_games_on_min_price"
    t.index ["min_tier", "max_tier"], name: "index_games_on_min_tier_and_max_tier"
    t.index ["start_time"], name: "index_games_on_start_time"
    t.index ["status"], name: "index_games_on_status"
    t.index ["venue_id"], name: "index_games_on_venue_id"
  end

  create_table "match_participations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.integer "team", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "winner", default: false
    t.index ["match_id", "user_id"], name: "index_match_participations_on_match_id_and_user_id", unique: true
    t.index ["match_id"], name: "index_match_participations_on_match_id"
    t.index ["user_id"], name: "index_match_participations_on_user_id"
  end

  create_table "matches", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "auto_promote", default: false, null: false
    t.integer "court_number"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.bigint "game_id", null: false
    t.integer "match_number", default: 1, null: false
    t.boolean "priority", default: false, null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.integer "team_a_score"
    t.integer "team_b_score"
    t.datetime "updated_at", null: false
    t.string "winner_team"
    t.index ["game_id", "court_number"], name: "index_matches_on_game_id_and_court_number"
    t.index ["game_id", "match_number"], name: "index_matches_on_game_id_and_match_number", unique: true
    t.index ["game_id", "priority"], name: "index_matches_on_game_id_and_priority"
    t.index ["game_id"], name: "index_matches_on_game_id"
  end

  create_table "ranks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "declared_rating"
    t.integer "declared_tier"
    t.integer "division", default: 3
    t.datetime "last_played_at"
    t.integer "losses", default: 0, null: false
    t.integer "matches_count", default: 0, null: false
    t.integer "play_time_seconds", default: 0, null: false
    t.integer "rating", default: 0, null: false
    t.integer "tier", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "wins", default: 0, null: false
    t.index ["rating"], name: "index_ranks_on_rating"
    t.index ["user_id"], name: "index_ranks_on_user_id", unique: true
  end

  create_table "user_skill_snapshots", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "agility", default: 5, null: false
    t.integer "attack", null: false
    t.decimal "computed_stars", precision: 3, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.integer "declared_rating", default: 0, null: false
    t.integer "declared_tier", default: 0, null: false
    t.integer "defense", default: 5, null: false
    t.integer "footwork", default: 5, null: false
    t.date "month", null: false
    t.decimal "overall_score", precision: 3, scale: 1, null: false
    t.integer "stamina", default: 5, null: false
    t.integer "technique", default: 5, null: false, comment: "Self-assessed technique score from 1 to 10"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "month"], name: "index_user_skill_snapshots_on_user_id_and_month", unique: true
    t.index ["user_id"], name: "index_user_skill_snapshots_on_user_id"
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
    t.string "avatar_key"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "email_verification_digest"
    t.datetime "email_verification_sent_at"
    t.datetime "email_verified_at"
    t.integer "gender", default: 0, null: false
    t.boolean "guest", default: false, null: false
    t.string "name", null: false
    t.string "password_digest"
    t.string "password_reset_digest"
    t.datetime "password_reset_sent_at"
    t.string "phone"
    t.boolean "placeholder", default: false, null: false
    t.datetime "session_active_at"
    t.string "session_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["placeholder"], name: "index_users_on_placeholder"
    t.index ["session_token"], name: "index_users_on_session_token", unique: true
  end

  create_table "venues", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "district"
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.string "mapbox_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["city"], name: "index_venues_on_city"
    t.index ["created_by_id"], name: "index_venues_on_created_by_id"
    t.index ["lat", "lng"], name: "index_venues_on_lat_and_lng"
    t.index ["mapbox_id"], name: "index_venues_on_mapbox_id", unique: true
  end

  add_foreign_key "game_participations", "games"
  add_foreign_key "game_participations", "users"
  add_foreign_key "game_player_pairs", "games"
  add_foreign_key "game_player_pairs", "users", column: "created_by_id"
  add_foreign_key "game_player_pairs", "users", column: "user_a_id"
  add_foreign_key "game_player_pairs", "users", column: "user_b_id"
  add_foreign_key "game_settlements", "games"
  add_foreign_key "game_settlements", "users", column: "updated_by_id"
  add_foreign_key "games", "users", column: "host_id"
  add_foreign_key "games", "venues"
  add_foreign_key "match_participations", "matches"
  add_foreign_key "match_participations", "users"
  add_foreign_key "matches", "games"
  add_foreign_key "ranks", "users"
  add_foreign_key "user_skill_snapshots", "users"
  add_foreign_key "user_skills", "users"
  add_foreign_key "venues", "users", column: "created_by_id"
end
