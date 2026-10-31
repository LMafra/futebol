require 'rails_helper'

RSpec.describe 'db/seeds.rb' do
  def seeded_models
    [Core::Team, Core::Player, Core::Championship, Core::Match, Core::User, Bolao::ScoringRule, Cartola::ScoringRule]
  end

  def counts = seeded_models.to_h { |model| [model.name, model.count] }

  def load_seed = expect { Rails.application.load_seed }.to output(/seeds ok/).to_stdout

  def round_of(match) = match.external_id[/-r(\d+)-/, 1]

  # Each load costs ~1.5s, so the data checks share one double load committed outside the example transactions.
  describe 'loaded twice in a row' do
    before(:context) do
      stdout = $stdout
      $stdout = StringIO.new
      Rails.application.load_seed
      @after_first_load = counts
      Rails.application.load_seed
    ensure
      $stdout = stdout
    end

    after(:context) do
      [Core::Match, Core::Player, Core::Team, Core::Championship, Core::Session, Core::User, Bolao::ScoringRule,
       Cartola::ScoringRule].each(&:delete_all)
    end

    it 'creates nothing new on the second load' do
      expect(@after_first_load.values).to all(be_positive)
      expect(counts).to eq(@after_first_load)
    end

    it 'seeds the 20 Série A teams' do
      expect(Core::Team.count).to eq(20)
      expect(Core::Team.pluck(:short_name)).to include('FLA', 'PAL', 'COR', 'SAO', 'REM', 'MIR')
    end

    it 'gives every team an 11-player squad (1 GOL, 2 LAT, 2 ZAG, 3 MEI, 3 ATA)' do
      Core::Team.includes(:players).find_each do |team|
        expect(team.players.map(&:position).tally).to eq('GOL' => 1, 'LAT' => 2, 'ZAG' => 2, 'MEI' => 3, 'ATA' => 3)
        expect(team.players.map(&:shirt_number)).to match_array(1..11)
      end
    end

    it 'seeds one demo championship with 38 rounds of 10 matches, each with a match_date' do
      championship = Core::Championship.sole
      rounds = championship.matches.group_by { |match| round_of(match) }

      expect(championship).to have_attributes(external_id: 'brasileirao-2026', season: 2026)
      expect(rounds.size).to eq(38)
      expect(rounds.values.map(&:size)).to all(eq(10))
      expect(championship.matches.where(match_date: nil)).to be_empty
    end

    it 'schedules a double round robin: every pairing once each way, nobody twice in a round' do
      pairings = Core::Match.pluck(:home_team_id, :away_team_id)

      expect(pairings.uniq.size).to eq(20 * 19)
      expect(pairings).to all(satisfy { |home, away| home != away })
      Core::Match.all.group_by { |match| round_of(match) }.each_value do |round|
        expect(round.flat_map { |match| [match.home_team_id, match.away_team_id] }.uniq.size).to eq(20)
      end
    end

    it 'seeds the global Bolão rule 10/7/5/3 and the default Cartola rule' do
      expect(Bolao::ScoringRule.for(nil)).to eq(exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3)
      expect(Cartola::ScoringRule.default)
        .to have_attributes(goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)
    end

    it 'creates exactly one admin' do
      expect(Core::User.where(admin: true).count).to eq(1)
    end
  end

  describe 'admin password' do
    around do |example|
      previous = ENV.fetch('SEED_ADMIN_PASSWORD', nil)
      ENV['SEED_ADMIN_PASSWORD'] = 'senha-vinda-do-env'
      example.run
    ensure
      ENV['SEED_ADMIN_PASSWORD'] = previous
    end

    it 'comes from SEED_ADMIN_PASSWORD' do
      load_seed

      admin = Core::User.find_by!(email_address: 'admin@futebol.dev')
      expect(admin).to be_admin
      expect(admin.authenticate('senha-vinda-do-env')).to eq(admin)
    end
  end

  describe 'production guard' do
    around do |example|
      previous = ENV.fetch('ALLOW_PRODUCTION_SEED', nil)
      ENV.delete('ALLOW_PRODUCTION_SEED')
      example.run
    ensure
      ENV['ALLOW_PRODUCTION_SEED'] = previous
    end

    it 'aborts without ALLOW_PRODUCTION_SEED and writes nothing' do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { Rails.application.load_seed }
        .to raise_error(SystemExit).and output(/ALLOW_PRODUCTION_SEED/).to_stderr
      expect(Core::Team.count).to eq(0)
    end
  end
end
