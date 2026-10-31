# Idempotent: every record is looked up by a natural key (external_id / email) before being created.
if Rails.env.production? && ENV['ALLOW_PRODUCTION_SEED'].blank?
  puts 'seeds skipped in production (set ALLOW_PRODUCTION_SEED=1 to force)'
  return
end

def seed_team(external_id:, name:, short_name:)
  Core::Team.find_or_create_by!(external_id:) do |team|
    team.name = name
    team.short_name = short_name
  end
end

teams = [
  seed_team(external_id: 'team-fla', name: 'Flamengo', short_name: 'FLA'),
  seed_team(external_id: 'team-pal', name: 'Palmeiras', short_name: 'PAL'),
  seed_team(external_id: 'team-cor', name: 'Corinthians', short_name: 'COR'),
  seed_team(external_id: 'team-sao', name: 'São Paulo', short_name: 'SAO')
]

{
  teams[0] => [['Agustín Rossi', 'GOL', 1], ['Giorgian De Arrascaeta', 'MEI', 10]],
  teams[1] => [['Weverton', 'GOL', 21], ['Raphael Veiga', 'MEI', 23]],
  teams[2] => [['Hugo Souza', 'GOL', 1], ['Yuri Alberto', 'ATA', 9]],
  teams[3] => [['Rafael', 'GOL', 23], ['Lucas Moura', 'ATA', 7]]
}.each do |team, players|
  players.each do |name, position, shirt_number|
    Core::Player.find_or_create_by!(external_id: "#{team.external_id}-#{shirt_number}") do |player|
      player.team = team
      player.name = name
      player.position = position
      player.shirt_number = shirt_number
    end
  end
end

championship = Core::Championship.find_or_create_by!(external_id: 'brasileirao-2026') do |record|
  record.name = 'Brasileirão Série A'
  record.season = 2026
end

Core::Match.find_or_create_by!(external_id: 'br26-r1-fla-pal') do |match|
  match.home_team = teams[0]
  match.away_team = teams[1]
  match.championship = championship
  match.match_date = Time.zone.parse('2026-11-08 16:00')
end

Core::Match.find_or_create_by!(external_id: 'br26-r1-cor-sao') do |match|
  match.home_team = teams[2]
  match.away_team = teams[3]
  match.championship = championship
  match.match_date = Time.zone.parse('2026-11-08 18:30')
end

if Rails.env.local?
  Core::User.find_or_create_by!(email_address: 'admin@futebol.dev') do |user|
    user.password = ENV.fetch('SEED_ADMIN_PASSWORD', 'futebol-admin')
    user.admin = true
  end
end

counts = [Core::Team, Core::Player, Core::Championship, Core::Match, Core::User].map do |model|
  "#{model.model_name.human.pluralize}=#{model.count}"
end
puts "seeds ok (#{counts.join(', ')})"
