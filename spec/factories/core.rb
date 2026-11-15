FactoryBot.define do
  factory :team, class: 'Core::Team' do
    sequence(:name) { |n| "Time #{n}" }
    sequence(:short_name) { |n| format('T%02d', n % 100) }
    sequence(:external_id) { |n| "team-#{n}" }
  end

  factory :player, class: 'Core::Player' do
    team
    sequence(:name) { |n| "Jogador #{n}" }
    position { 'MEI' }
    sequence(:shirt_number) { |n| (n % 99) + 1 }
    sequence(:external_id) { |n| "player-#{n}" }
  end

  factory :championship, class: 'Core::Championship' do
    name { 'Brasileirão Série A' }
    season { 2026 }
    sequence(:external_id) { |n| "championship-#{n}" }
  end

  factory :match, class: 'Core::Match' do
    home_team factory: :team
    away_team factory: :team
    championship
    match_date { 2.days.from_now }
    status { 'scheduled' }
    sequence(:external_id) { |n| "match-#{n}" }

    # Matches only take teams enrolled in their championship, owned by its manager (ADR 0006).
    before(:create) do |match|
      [match.home_team, match.away_team].each do |team|
        # update_column: saving the team would autosave this match before its teams are enrolled.
        team.update_column(:manager_id, match.championship.manager_id) if team.championship_teams.none?
        match.championship.championship_teams.find_or_create_by!(team:)
      end
    end
  end

  factory :audit_log, class: 'Core::AuditLog' do
    action { 'revert' }
    ip_address { '127.0.0.1' }
  end

  factory :csv_import, class: 'Core::CsvImport'
end
