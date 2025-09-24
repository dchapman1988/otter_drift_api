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

ActiveRecord::Schema[8.0].define(version: 2025_09_24_170058) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "game_sessions", force: :cascade do |t|
    t.uuid "session_id"
    t.string "player_name"
    t.integer "seed"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "final_score"
    t.float "game_duration"
    t.float "max_speed_reached"
    t.integer "obstacles_avoided"
    t.integer "lilies_collected"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "high_scores", force: :cascade do |t|
    t.bigint "game_session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_session_id"], name: "index_high_scores_on_game_session_id"
  end

  add_foreign_key "high_scores", "game_sessions"
end
