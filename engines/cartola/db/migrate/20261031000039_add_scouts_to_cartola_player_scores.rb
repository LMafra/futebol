# Official scouts of a player in a match: G, A, DP, DE, CA, CV and GC, plus "Jogou", "Destaque" and SG (derived by
# Cartola::RecordScoutsService). team_id is the side the player was on in that match; existing rows (none in
# production) take the player's current team.
class AddScoutsToCartolaPlayerScores < ActiveRecord::Migration[8.1]
  SCOUT_MAXIMUMS = { goals: 20, assists: 20, own_goals: 20, saves: 20, penalty_saves: 3, yellow_cards: 2,
                     red_cards: 1 }.freeze
  FLAGS = %i[played highlight clean_sheet].freeze

  def up
    add_column :cartola_player_scores, :team_id, :bigint
    SCOUT_MAXIMUMS.each_key { |column| add_column :cartola_player_scores, column, :integer, null: false, default: 0 }
    FLAGS.each { |column| add_column :cartola_player_scores, column, :boolean, null: false, default: false }

    safety_assured do
      execute <<~SQL.squish
        UPDATE cartola_player_scores SET team_id = core_players.team_id
        FROM core_players WHERE core_players.id = cartola_player_scores.player_id
      SQL
      change_column_null :cartola_player_scores, :team_id, false
      add_foreign_key :cartola_player_scores, :core_teams, column: :team_id
      add_index :cartola_player_scores, :team_id
      SCOUT_MAXIMUMS.each do |column, maximum|
        add_check_constraint :cartola_player_scores, "#{column} BETWEEN 0 AND #{maximum}",
                             name: "cartola_player_scores_#{column}_range"
      end
      add_index :cartola_player_scores, :match_id, unique: true, where: 'highlight AND discarded_at IS NULL',
                                                   name: 'index_cartola_player_scores_one_highlight'
    end
  end

  def down
    safety_assured do
      remove_index :cartola_player_scores, name: 'index_cartola_player_scores_one_highlight'
      SCOUT_MAXIMUMS.each_key do |column|
        remove_check_constraint :cartola_player_scores, name: "cartola_player_scores_#{column}_range"
      end
      remove_foreign_key :cartola_player_scores, column: :team_id
      (%i[team_id] + SCOUT_MAXIMUMS.keys + FLAGS).each { |column| remove_column :cartola_player_scores, column }
    end
  end
end
