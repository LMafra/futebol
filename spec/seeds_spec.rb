require 'rails_helper'

RSpec.describe 'db/seeds.rb' do
  def seeded_models
    [Core::Team, Core::Player, Core::Championship, Core::Match, Core::User, Bolao::ScoringRule, Cartola::ScoringRule,
     Bolao::Pool, Bolao::PoolMembership, Bolao::Prediction, Bolao::PredictionScore, Cartola::Squad, Cartola::Lineup,
     Cartola::LineupPlayer, Cartola::Wallet]
  end

  def counts = seeded_models.to_h { |model| [model.name, model.count] }

  def load_seed = expect { Rails.application.load_seed }.to output(/seeds ok/).to_stdout

  def round_of(match) = match.round

  def matches_in_rounds(rounds) = Core::Match.select { |match| round_of(match).to_i.in?(rounds) }

  def demo_users = Core::User.where('email_address LIKE ?', '%@demo.local')

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
      [Bolao::PredictionScore, Bolao::Prediction, Bolao::PoolMembership, Bolao::ScoringRule, Bolao::Pool,
       Cartola::Wallet, Cartola::LineupPlayer, Cartola::Lineup, Cartola::Squad, Cartola::ScoringRule, Core::Match, Core::Player,
       Core::Team, Core::Championship, Core::Session, Core::User].each(&:delete_all)
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
      expect(rounds.keys).to match_array(1..38)
      expect(championship.matches).to all(satisfy { |match|
        match.external_id.include?(format('-r%02d-', match.round))
      })
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

    it 'seeds the global Bolão rule 10/5 and the default Cartola rule' do
      expect(Bolao::ScoringRule.for(nil)).to have_attributes(persisted?: true, exact_score_points: 10, winner_points: 5)
      expect(Cartola::ScoringRule.default)
        .to have_attributes(goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)
    end

    it 'creates exactly one admin' do
      expect(Core::User.where(admin: true).count).to eq(1)
    end

    describe 'demo data' do
      it 'creates demo1..demo5@demo.local, non-admin, with the documented password' do
        expect(demo_users.pluck(:email_address)).to match_array((1..5).map { |n| "demo#{n}@demo.local" })
        expect(demo_users).to all(satisfy { |user| !user.admin? && user.authenticate('demo-futebol') })
      end

      it 'puts the 5 demo users in pool DEMO01, owned by demo1' do
        pool = Bolao::Pool.find_by!(code: 'DEMO01')

        expect(pool.owner.email_address).to eq('demo1@demo.local')
        expect(pool.members).to match_array(demo_users)
      end

      it 'scores rounds 1-4 and 6, leaves round 5 live and rounds 7-10 scheduled in the future' do
        expect(matches_in_rounds([1, 2, 3, 4, 6])).to all(have_attributes(status: 'scored', home_score: Integer,
                                                                          away_score: Integer))
        expect(matches_in_rounds([5]).map(&:status)).to all(eq('live'))
        expect(matches_in_rounds(7..10)).to all(have_attributes(status: 'scheduled'))
        expect(matches_in_rounds(7..10).map(&:match_date)).to all(be_future)
        expect(matches_in_rounds(11..38).map(&:status)).to all(eq('scheduled'))
      end

      it 'keeps rounds 7-10 in order after moving them to the future' do
        first_kickoffs = (7..10).map { |round| matches_in_rounds([round]).map(&:match_date).min }

        expect(first_kickoffs.each_cons(2).map { |earlier, later| later - earlier }).to all(eq(1.week))
      end

      it 'spreads at least 60 predictions over the 5 users and 10 rounds, one per (pool, user, match)' do
        predictions = Bolao::Prediction.includes(:user, :match)

        expect(predictions.size).to be >= 60
        expect(predictions.map(&:user).uniq).to match_array(demo_users)
        expect(predictions.map { |prediction| round_of(prediction.match).to_i }.uniq).to match_array(1..10)
        expect(predictions.map { |prediction| [prediction.pool_id, prediction.user_id, prediction.match_id] }.uniq.size)
          .to eq(predictions.size)
      end

      it 'gives every prediction on a scored match a kept score, and none to the others' do
        scored, pending = Bolao::Prediction.includes(:match, :scores).partition { |prediction| prediction.match.scored? }

        expect(scored).to all(satisfy { |prediction| prediction.scores.kept.one? })
        expect(pending.flat_map(&:scores)).to be_empty
        expect(Bolao::PredictionScore.sum(:points)).to be_positive
      end

      it "buys demo1's round 7 lineup within the championship limits, from demo1's wallet" do
        lineup = Cartola::Lineup.joins(squad: :user)
                                .find_by!(round: 7, core_users: { email_address: 'demo1@demo.local' })
        cost = Cartola::PlayerValue.prices_for(lineup.players, lineup.championship).values.sum
        wallet = Cartola::Wallet.find_by!(user: lineup.squad.user, championship: lineup.championship)

        expect(lineup).to be_valid
        expect(lineup.lineup_players.map(&:position).tally)
          .to eq('goalkeeper' => 1, 'defender' => 2, 'midfielder' => 3, 'forward' => 3)
        expect(wallet.balance).to eq(lineup.championship.cartola_initial_budget - cost)
        expect(wallet.balance).to be_positive
      end
    end
  end

  describe 'outside development/test' do
    around do |example|
      previous = ENV.fetch('SEED_ADMIN_PASSWORD', nil)
      ENV['SEED_ADMIN_PASSWORD'] = 'senha-vinda-do-env'
      example.run
    ensure
      ENV['SEED_ADMIN_PASSWORD'] = previous
    end

    it 'skips the demo data, whose password is public' do
      allow(Rails.env).to receive(:local?).and_return(false)

      load_seed

      expect(demo_users).to be_empty
      expect(Bolao::Pool.count).to eq(0)
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
