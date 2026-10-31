module Seeds
  def self.teams
    YAML.load_file(Rails.root.join('db/seeds/teams.yml'), symbolize_names: true).map do |attributes|
      Core::Team.find_or_create_by!(external_id: attributes[:external_id]) do |team|
        team.name = attributes[:name]
        team.short_name = attributes[:short_name]
      end
    end
  end
end
