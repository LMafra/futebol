# Derived ticket of ADR 0003 (§9): rounds were only encoded in the seed external_id (br26-rNN-...), which CSV
# imports do not follow. Backfills from that pattern; other rows stay NULL until imported with a round column.
class AddRoundToCoreMatches < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :core_matches, :round, :integer
    add_check_constraint :core_matches, 'round IS NULL OR round BETWEEN 1 AND 38', name: 'matches_round_range',
                                                                                   validate: false
    safety_assured do
      execute <<~SQL.squish
        UPDATE core_matches SET round = substring(external_id from '-r([0-9]{1,2})-')::integer
        WHERE external_id ~ '-r[0-9]{1,2}-' AND substring(external_id from '-r([0-9]{1,2})-')::integer BETWEEN 1 AND 38
      SQL
    end
    validate_check_constraint :core_matches, name: 'matches_round_range'
    add_index :core_matches, %i[championship_id round], algorithm: :concurrently
  end

  def down
    remove_index :core_matches, %i[championship_id round], algorithm: :concurrently
    remove_column :core_matches, :round
  end
end
