class BackfillCartolaScoutEvents < ActiveRecord::Migration[8.1]
  def up = Cartola::ScoutEventBackfill.new(connection).up
  def down = Cartola::ScoutEventBackfill.new(connection).down
end
