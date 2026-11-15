class AssignTeamsToManagers < ActiveRecord::Migration[8.1]
  def up = Core::TeamOwnershipBackfill.new(connection).up
  def down = Core::TeamOwnershipBackfill.new(connection).down
end
