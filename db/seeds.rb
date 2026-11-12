# Idempotent: every record is looked up by its natural key (external_id / name / email) before being created.
if Rails.env.production? && ENV['ALLOW_PRODUCTION_SEED'].blank?
  abort 'seeds blocked in production (set ALLOW_PRODUCTION_SEED=1 to force)'
end

%w[teams players championships matches scoring_rules users demo lineups scouts small_championships].each do |name|
  load Rails.root.join("db/seeds/#{name}.rb")
end

ActiveRecord::Base.transaction do
  teams = Seeds.teams
  Seeds.players(teams)
  Seeds.matches(Seeds.championship, teams)
  Seeds.scoring_rules
  Seeds.admin
  # The demo password is public (README), so these accounts never reach a deployed database.
  if Rails.env.local?
    Seeds.demo(Seeds.championship)
    Seeds.demo_manager(Seeds.small_championships.first)
  end
end

seeded_models = [Core::Team, Core::Player, Core::Championship, Core::Match, Core::User, Bolao::ScoringRule,
                 Cartola::ScoringRule, Bolao::Pool, Bolao::PoolMembership, Bolao::Prediction,
                 Bolao::PredictionScore, Cartola::Squad, Cartola::Lineup, Cartola::LineupPlayer, Cartola::Wallet,
                 Cartola::PlayerScore]
puts "seeds ok (#{seeded_models.map { |model| "#{model.name}=#{model.count}" }.join(', ')})"
