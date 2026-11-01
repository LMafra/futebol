# Lineups follow the limits of one championship. Existing ones (only the demo seed) move to the latest
# championship. lineup_players.position stores the slot (goalkeeper/defender/midfielder/forward) the player fills,
# mapped from core_players.position (GOL/LAT/ZAG/MEI/ATA), which stays as it is.
class ScopeCartolaLineupsByChampionship < ActiveRecord::Migration[8.1]
  POSITION_SLOT = <<~SQL.squish.freeze
    CASE core_players.position WHEN 'GOL' THEN 'goalkeeper' WHEN 'LAT' THEN 'defender' WHEN 'ZAG' THEN 'defender'
    WHEN 'MEI' THEN 'midfielder' WHEN 'ATA' THEN 'forward' END
  SQL

  def up
    add_column :cartola_lineups, :championship_id, :bigint
    add_column :cartola_lineup_players, :position, :string

    safety_assured do
      execute <<~SQL.squish
        UPDATE cartola_lineups SET championship_id =
          (SELECT id FROM core_championships ORDER BY season DESC, id DESC LIMIT 1)
      SQL
      execute <<~SQL.squish
        UPDATE cartola_lineup_players SET position = #{POSITION_SLOT}
        FROM core_players WHERE core_players.id = cartola_lineup_players.player_id
      SQL
      change_column_null :cartola_lineups, :championship_id, false
      change_column_null :cartola_lineup_players, :position, false

      add_foreign_key :cartola_lineups, :core_championships, column: :championship_id
      remove_index :cartola_lineups, %i[squad_id round]
      add_index :cartola_lineups, %i[squad_id championship_id round], unique: true
      add_index :cartola_lineups, :championship_id
      add_check_constraint :cartola_lineup_players,
                           "position IN ('goalkeeper','defender','midfielder','forward')",
                           name: 'cartola_lineup_players_position_valid'
    end
  end

  def down
    safety_assured do
      remove_check_constraint :cartola_lineup_players, name: 'cartola_lineup_players_position_valid'
      remove_index :cartola_lineups, :championship_id
      remove_index :cartola_lineups, %i[squad_id championship_id round]
      add_index :cartola_lineups, %i[squad_id round], unique: true
      remove_foreign_key :cartola_lineups, column: :championship_id
      remove_column :cartola_lineup_players, :position
      remove_column :cartola_lineups, :championship_id
    end
  end
end
