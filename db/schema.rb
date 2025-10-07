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

ActiveRecord::Schema[8.0].define(version: 2025_10_07_193925) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "description"
    t.string "icon_url"
    t.bigint "points"
    t.boolean "hidden", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "earned_achievements", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "achievement_id", null: false
    t.bigint "game_session_id"
    t.datetime "earned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_earned_achievements_on_achievement_id"
    t.index ["earned_at"], name: "index_earned_achievements_on_earned_at"
    t.index ["game_session_id"], name: "index_earned_achievements_on_game_session_id"
    t.index ["player_id", "achievement_id"], name: "index_earned_achievements_on_player_id_and_achievement_id", unique: true
    t.index ["player_id"], name: "index_earned_achievements_on_player_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.string "session_id"
    t.string "player_name"
    t.bigint "seed"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "final_score"
    t.float "game_duration"
    t.float "max_speed_reached"
    t.integer "obstacles_avoided"
    t.integer "lilies_collected"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "player_id"
    t.integer "hearts_collected"
    t.index ["player_id", "created_at"], name: "index_game_sessions_on_player_id_and_created_at"
    t.index ["player_id", "final_score"], name: "index_game_sessions_on_player_id_and_final_score", order: { final_score: :desc }
    t.index ["player_id"], name: "index_game_sessions_on_player_id"
  end

  create_table "high_scores", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "score"
    t.index ["game_session_id"], name: "index_high_scores_on_game_session_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "players", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "username", null: false
    t.string "display_name"
    t.string "avatar_url"
    t.integer "total_score", default: 0
    t.integer "games_played", default: 0
    t.datetime "last_played_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_players_on_email", unique: true
    t.index ["reset_password_token"], name: "index_players_on_reset_password_token", unique: true
    t.index ["username"], name: "index_players_on_username", unique: true
  end

  add_foreign_key "earned_achievements", "achievements"
  add_foreign_key "earned_achievements", "game_sessions"
  add_foreign_key "earned_achievements", "players"
  add_foreign_key "game_sessions", "players"
  add_foreign_key "high_scores", "game_sessions"
end
