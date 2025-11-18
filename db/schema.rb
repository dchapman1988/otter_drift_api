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

ActiveRecord::Schema[8.1].define(version: 2025_11_13_154241) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.string "achievement_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "hidden", default: false
    t.string "icon_url"
    t.string "name"
    t.bigint "points"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["achievement_type"], name: "index_achievements_on_achievement_type", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "earned_achievements", force: :cascade do |t|
    t.bigint "achievement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "earned_at"
    t.bigint "game_session_id"
    t.bigint "player_id", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_earned_achievements_on_achievement_id"
    t.index ["earned_at"], name: "index_earned_achievements_on_earned_at"
    t.index ["game_session_id"], name: "index_earned_achievements_on_game_session_id"
    t.index ["player_id", "achievement_id"], name: "index_earned_achievements_on_player_id_and_achievement_id", unique: true
    t.index ["player_id"], name: "index_earned_achievements_on_player_id"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "final_score"
    t.float "game_duration"
    t.integer "hearts_collected"
    t.integer "lilies_collected"
    t.float "max_speed_reached"
    t.integer "obstacles_avoided"
    t.bigint "player_id"
    t.string "player_name"
    t.bigint "seed"
    t.string "session_id"
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.index ["player_id", "created_at"], name: "index_game_sessions_on_player_id_and_created_at"
    t.index ["player_id", "final_score"], name: "index_game_sessions_on_player_id_and_final_score", order: { final_score: :desc }
    t.index ["player_id"], name: "index_game_sessions_on_player_id"
  end

  create_table "high_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_session_id", null: false
    t.bigint "score"
    t.datetime "updated_at", null: false
    t.index ["game_session_id"], name: "index_high_scores_on_game_session_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "player_profiles", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.text "favorite_otter_fact"
    t.string "location"
    t.bigint "player_id", null: false
    t.string "profile_banner_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["location"], name: "index_player_profiles_on_location"
    t.index ["player_id"], name: "index_player_profiles_on_player_id"
    t.index ["title"], name: "index_player_profiles_on_title"
  end

  create_table "players", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "games_played", default: 0
    t.datetime "last_played_at"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.integer "total_score", default: 0
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_players_on_email", unique: true
    t.index ["reset_password_token"], name: "index_players_on_reset_password_token", unique: true
    t.index ["username"], name: "index_players_on_username", unique: true
  end

  create_table "suggestions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.bigint "player_id"
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_suggestions_on_player_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "earned_achievements", "achievements"
  add_foreign_key "earned_achievements", "game_sessions"
  add_foreign_key "earned_achievements", "players"
  add_foreign_key "game_sessions", "players"
  add_foreign_key "high_scores", "game_sessions", on_delete: :cascade
  add_foreign_key "player_profiles", "players"
  add_foreign_key "suggestions", "players"
end
