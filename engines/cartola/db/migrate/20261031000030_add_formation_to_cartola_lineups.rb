class AddFormationToCartolaLineups < ActiveRecord::Migration[8.1]
  # Same list as Cartola::Lineup::FORMATIONS; duplicated so the migration never depends on the model.
  FORMATIONS = %w[3-4-3 3-5-2 4-3-3 4-4-2 4-5-1 5-3-2 5-4-1].freeze

  def change
    add_column :cartola_lineups, :formation, :string, null: false, default: '4-3-3'
    add_check_constraint :cartola_lineups, "formation IN (#{FORMATIONS.map { |f| "'#{f}'" }.join(', ')})",
                         name: 'cartola_lineups_formation_valid'
  end
end
