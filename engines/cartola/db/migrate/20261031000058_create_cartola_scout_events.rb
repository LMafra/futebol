class CreateCartolaScoutEvents < ActiveRecord::Migration[8.1]
  STATS = %w[goals assists penalty_saves saves yellow_cards red_cards own_goals].freeze
  PERIODS = %w[first_half second_half extra_time penalties].freeze

  def change
    create_table :cartola_scout_events do |t|
      t.references :match, null: false, foreign_key: { to_table: :core_matches }, index: false
      t.references :player, null: false, foreign_key: { to_table: :core_players }
      t.references :team, null: false, foreign_key: { to_table: :core_teams }
      t.references :recorded_by, foreign_key: { to_table: :core_users }
      t.string :stat, null: false
      t.string :period
      t.integer :minute
      t.datetime :discarded_at

      t.timestamps

      t.index %i[match_id player_id stat], where: 'discarded_at IS NULL', name: 'index_cartola_scout_events_kept'
      t.index :match_id
      t.check_constraint "stat IN (#{STATS.map { "'#{_1}'" }.join(', ')})", name: 'cartola_scout_events_stat'
      t.check_constraint "period IS NULL OR period IN (#{PERIODS.map { "'#{_1}'" }.join(', ')})",
                         name: 'cartola_scout_events_period'
      t.check_constraint 'minute IS NULL OR (minute >= 0 AND minute <= 130)', name: 'cartola_scout_events_minute'
    end
  end
end
