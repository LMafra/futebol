class ImportTeamCrestUrls < ActiveRecord::Migration[8.1]
  def up = Core::CrestUrlImport.new(connection).run

  # The imported crests stay: they are ordinary attachments by now, possibly replaced since.
  def down; end
end
