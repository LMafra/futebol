# Idempotent: every record is looked up by its natural key (external_id / name / email) before being created.
if Rails.env.production? && ENV['ALLOW_PRODUCTION_SEED'].blank?
  abort 'seeds blocked in production (set ALLOW_PRODUCTION_SEED=1 to force)'
end

%w[teams players championships matches scoring_rules users].each do |name|
  load Rails.root.join("db/seeds/#{name}.rb")
end

ActiveRecord::Base.transaction do
  teams = Seeds.teams
  Seeds.players(teams)
  Seeds.matches(Seeds.championship, teams)
  Seeds.scoring_rules
  Seeds.admin
end

seeded_models = [Core::Team, Core::Player, Core::Championship, Core::Match, Core::User, Bolao::ScoringRule,
                 Cartola::ScoringRule]
puts "seeds ok (#{seeded_models.map { |model| "#{model.name}=#{model.count}" }.join(', ')})"
