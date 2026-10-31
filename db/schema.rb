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

ActiveRecord::Schema[8.1].define(version: 2026_10_31_000015) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "core_audit_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "action", null: false
    t.string "auditable_type"
    t.bigint "auditable_id"
    t.inet "ip_address", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_core_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_core_audit_logs_on_auditable"
    t.index ["user_id"], name: "index_core_audit_logs_on_user_id"
  end

  create_table "core_championships", force: :cascade do |t|
    t.string "name", null: false
    t.integer "season", null: false
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_core_championships_on_external_id", unique: true
    t.check_constraint "season >= 1900 AND season <= 2100", name: "core_championships_season_range"
  end

  create_table "core_csv_imports", force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.text "error_message"
    t.integer "rows_processed", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "rows_processed >= 0", name: "csv_imports_rows_non_negative"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying]::text[])", name: "csv_imports_status_valid"
  end

  create_table "core_matches", force: :cascade do |t|
    t.bigint "home_team_id", null: false
    t.bigint "away_team_id", null: false
    t.bigint "championship_id", null: false
    t.datetime "match_date", null: false
    t.integer "home_score"
    t.integer "away_score"
    t.string "status", default: "scheduled", null: false
    t.datetime "scores_calculated_at"
    t.uuid "scoring_token"
    t.uuid "reversal_token"
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["away_team_id"], name: "index_core_matches_on_away_team_id"
    t.index ["championship_id"], name: "index_core_matches_on_championship_id"
    t.index ["external_id"], name: "index_core_matches_on_external_id", unique: true
    t.index ["home_team_id"], name: "index_core_matches_on_home_team_id"
    t.index ["match_date"], name: "index_core_matches_on_match_date"
    t.index ["scoring_token"], name: "index_core_matches_on_scoring_token", unique: true, where: "(scoring_token IS NOT NULL)"
    t.check_constraint "home_score >= 0 AND away_score >= 0", name: "matches_scores_non_negative"
    t.check_constraint "home_team_id <> away_team_id", name: "matches_distinct_teams"
    t.check_constraint "scores_calculated_at IS NULL OR (status::text = ANY (ARRAY['finished'::character varying, 'scored'::character varying]::text[]))", name: "matches_timestamp_after_finish"
    t.check_constraint "status::text <> 'scored'::text OR scores_calculated_at IS NOT NULL", name: "matches_scored_has_timestamp"
    t.check_constraint "status::text = ANY (ARRAY['scheduled'::character varying, 'live'::character varying, 'finished'::character varying, 'scored'::character varying, 'reverted'::character varying]::text[])", name: "matches_status_valid"
  end

  create_table "core_players", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.string "name", null: false
    t.string "position", null: false
    t.integer "shirt_number"
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_core_players_on_external_id", unique: true
    t.index ["team_id", "shirt_number"], name: "index_core_players_on_team_id_and_shirt_number", unique: true, where: "(shirt_number IS NOT NULL)"
    t.index ["team_id"], name: "index_core_players_on_team_id"
    t.check_constraint "\"position\"::text = ANY (ARRAY['GOL'::character varying, 'LAT'::character varying, 'ZAG'::character varying, 'MEI'::character varying, 'ATA'::character varying]::text[])", name: "players_position_valid"
    t.check_constraint "shirt_number >= 1 AND shirt_number <= 99", name: "players_shirt_number_range"
  end

  create_table "core_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_core_sessions_on_user_id"
  end

  create_table "core_teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", null: false
    t.string "crest_url"
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_core_teams_on_external_id", unique: true
    t.index ["short_name"], name: "index_core_teams_on_short_name", unique: true
    t.check_constraint "char_length(short_name::text) = 3", name: "core_teams_short_name_length"
  end

  create_table "core_users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_core_users_on_email_address", unique: true
  end

  add_foreign_key "core_audit_logs", "core_users", column: "user_id"
  add_foreign_key "core_matches", "core_championships", column: "championship_id"
  add_foreign_key "core_matches", "core_teams", column: "away_team_id"
  add_foreign_key "core_matches", "core_teams", column: "home_team_id"
  add_foreign_key "core_players", "core_teams", column: "team_id"
  add_foreign_key "core_sessions", "core_users", column: "user_id"
end
