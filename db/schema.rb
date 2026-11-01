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

ActiveRecord::Schema[8.1].define(version: 2026_10_31_000028) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bolao_pool_memberships", force: :cascade do |t|
    t.bigint "pool_id", null: false
    t.bigint "user_id", null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pool_id", "user_id"], name: "index_bolao_pool_memberships_on_pool_id_and_user_id", unique: true
    t.index ["pool_id"], name: "index_bolao_pool_memberships_on_pool_id"
    t.index ["user_id"], name: "index_bolao_pool_memberships_on_user_id"
  end

  create_table "bolao_pools", force: :cascade do |t|
    t.bigint "championship_id", null: false
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code", limit: 6, null: false
    t.index ["championship_id"], name: "index_bolao_pools_on_championship_id"
    t.index ["code"], name: "index_bolao_pools_on_code", unique: true
    t.index ["owner_id"], name: "index_bolao_pools_on_owner_id"
  end

  create_table "bolao_prediction_scores", force: :cascade do |t|
    t.bigint "prediction_id", null: false
    t.integer "points", null: false
    t.uuid "scoring_token", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_bolao_prediction_scores_on_discarded_at"
    t.index ["prediction_id", "scoring_token"], name: "idx_on_prediction_id_scoring_token_acdf12d38b", unique: true
    t.index ["scoring_token"], name: "index_bolao_prediction_scores_on_scoring_token"
    t.check_constraint "points >= 0", name: "bolao_prediction_scores_points_non_negative"
  end

  create_table "bolao_predictions", force: :cascade do |t|
    t.bigint "pool_id", null: false
    t.bigint "user_id", null: false
    t.bigint "match_id", null: false
    t.integer "home_guess", null: false
    t.integer "away_guess", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_bolao_predictions_on_discarded_at"
    t.index ["match_id"], name: "index_bolao_predictions_on_match_id"
    t.index ["pool_id", "user_id", "match_id"], name: "index_bolao_predictions_kept_unique", unique: true, where: "(discarded_at IS NULL)"
    t.index ["pool_id"], name: "index_bolao_predictions_on_pool_id"
    t.index ["user_id"], name: "index_bolao_predictions_on_user_id"
    t.check_constraint "home_guess >= 0 AND away_guess >= 0", name: "bolao_predictions_guesses_non_negative"
  end

  create_table "bolao_scoring_rules", force: :cascade do |t|
    t.bigint "pool_id"
    t.string "kind", null: false
    t.integer "points", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pool_id", "kind"], name: "index_bolao_scoring_rules_on_pool_id_and_kind", unique: true, nulls_not_distinct: true
    t.check_constraint "kind::text = ANY (ARRAY['exact_score'::character varying::text, 'winner_and_goal_diff'::character varying::text, 'winner'::character varying::text, 'draw'::character varying::text])", name: "bolao_scoring_rules_kind_valid"
    t.check_constraint "points >= 0", name: "bolao_scoring_rules_points_non_negative"
  end

  create_table "cartola_lineup_players", force: :cascade do |t|
    t.bigint "lineup_id", null: false
    t.bigint "player_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lineup_id", "player_id"], name: "index_cartola_lineup_players_on_lineup_id_and_player_id", unique: true
    t.index ["lineup_id"], name: "index_cartola_lineup_players_on_lineup_id"
    t.index ["player_id"], name: "index_cartola_lineup_players_on_player_id"
  end

  create_table "cartola_lineups", force: :cascade do |t|
    t.bigint "squad_id", null: false
    t.integer "round", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["squad_id", "round"], name: "index_cartola_lineups_on_squad_id_and_round", unique: true
    t.index ["squad_id"], name: "index_cartola_lineups_on_squad_id"
    t.check_constraint "round >= 1 AND round <= 38", name: "cartola_lineups_round_range"
  end

  create_table "cartola_player_scores", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "match_id", null: false
    t.decimal "points", precision: 6, scale: 2, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_cartola_player_scores_on_discarded_at"
    t.index ["match_id"], name: "index_cartola_player_scores_on_match_id"
    t.index ["player_id", "match_id"], name: "index_cartola_player_scores_kept_unique", unique: true, where: "(discarded_at IS NULL)"
    t.index ["player_id"], name: "index_cartola_player_scores_on_player_id"
  end

  create_table "cartola_scoring_rules", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "goal_points", precision: 5, scale: 2, null: false
    t.decimal "assist_points", precision: 5, scale: 2, null: false
    t.decimal "yellow_card_penalty", precision: 5, scale: 2, null: false
    t.decimal "red_card_penalty", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_cartola_scoring_rules_on_name", unique: true
    t.check_constraint "assist_points >= 0::numeric", name: "cartola_scoring_rules_assist_points_non_negative"
    t.check_constraint "goal_points >= 0::numeric", name: "cartola_scoring_rules_goal_points_non_negative"
    t.check_constraint "red_card_penalty >= 0::numeric", name: "cartola_scoring_rules_red_card_penalty_non_negative"
    t.check_constraint "yellow_card_penalty >= 0::numeric", name: "cartola_scoring_rules_yellow_card_penalty_non_negative"
  end

  create_table "cartola_squads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_cartola_squads_on_user_id"
  end

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
    t.text "error_log"
    t.check_constraint "rows_processed >= 0", name: "csv_imports_rows_non_negative"
    t.check_constraint "status::text <> 'failed'::text OR error_message IS NOT NULL AND error_log IS NOT NULL", name: "csv_imports_failed_has_error"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'processing'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text])", name: "csv_imports_status_valid"
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
    t.check_constraint "scores_calculated_at IS NULL OR (status::text = ANY (ARRAY['finished'::character varying::text, 'scored'::character varying::text]))", name: "matches_timestamp_after_finish"
    t.check_constraint "status::text <> 'scored'::text OR scores_calculated_at IS NOT NULL", name: "matches_scored_has_timestamp"
    t.check_constraint "status::text = ANY (ARRAY['scheduled'::character varying::text, 'live'::character varying::text, 'finished'::character varying::text, 'scored'::character varying::text, 'reverted'::character varying::text])", name: "matches_status_valid"
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
    t.check_constraint "\"position\"::text = ANY (ARRAY['GOL'::character varying::text, 'LAT'::character varying::text, 'ZAG'::character varying::text, 'MEI'::character varying::text, 'ATA'::character varying::text])", name: "players_position_valid"
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
    t.string "name"
    t.string "cpf"
    t.boolean "active", default: true, null: false
    t.datetime "anonymized_at"
    t.index ["cpf"], name: "index_core_users_on_cpf", unique: true, where: "(cpf IS NOT NULL)"
    t.index ["email_address"], name: "index_core_users_on_email_address", unique: true
    t.check_constraint "anonymized_at IS NULL OR NOT active AND cpf IS NULL", name: "core_users_anonymized_inactive"
    t.check_constraint "cpf IS NULL OR cpf::text ~ '^[0-9]{11}$'::text", name: "core_users_cpf_digits"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bolao_pool_memberships", "bolao_pools", column: "pool_id"
  add_foreign_key "bolao_pool_memberships", "core_users", column: "user_id"
  add_foreign_key "bolao_pools", "core_championships", column: "championship_id"
  add_foreign_key "bolao_pools", "core_users", column: "owner_id"
  add_foreign_key "bolao_prediction_scores", "bolao_predictions", column: "prediction_id"
  add_foreign_key "bolao_predictions", "bolao_pools", column: "pool_id"
  add_foreign_key "bolao_predictions", "core_matches", column: "match_id"
  add_foreign_key "bolao_predictions", "core_users", column: "user_id"
  add_foreign_key "bolao_scoring_rules", "bolao_pools", column: "pool_id"
  add_foreign_key "cartola_lineup_players", "cartola_lineups", column: "lineup_id"
  add_foreign_key "cartola_lineup_players", "core_players", column: "player_id"
  add_foreign_key "cartola_lineups", "cartola_squads", column: "squad_id"
  add_foreign_key "cartola_player_scores", "core_matches", column: "match_id"
  add_foreign_key "cartola_player_scores", "core_players", column: "player_id"
  add_foreign_key "cartola_squads", "core_users", column: "user_id"
  add_foreign_key "core_audit_logs", "core_users", column: "user_id"
  add_foreign_key "core_matches", "core_championships", column: "championship_id"
  add_foreign_key "core_matches", "core_teams", column: "away_team_id"
  add_foreign_key "core_matches", "core_teams", column: "home_team_id"
  add_foreign_key "core_players", "core_teams", column: "team_id"
  add_foreign_key "core_sessions", "core_users", column: "user_id"
end
