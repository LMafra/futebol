# The captain's points count twice in the Esquadrão ranking; at most one captain per lineup.
class AddCaptainToCartolaLineupPlayers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :cartola_lineup_players, :captain, :boolean, default: false, null: false
    add_index :cartola_lineup_players, :lineup_id, unique: true, where: 'captain', algorithm: :concurrently,
                                                   name: 'index_cartola_lineup_players_one_captain'
  end
end
