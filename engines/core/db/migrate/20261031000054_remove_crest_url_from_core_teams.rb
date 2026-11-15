class RemoveCrestUrlFromCoreTeams < ActiveRecord::Migration[8.1]
  def change
    # Read by nothing since the crest became an attachment; the import ran in the previous migration.
    safety_assured { remove_column :core_teams, :crest_url, :string }
  end
end
