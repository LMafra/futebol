require 'rails_helper'

RSpec.describe Core::ChampionshipRankingsService do
  let(:championship) { create(:championship) }

  def fan(name, consented: true)
    create(:user, name:, public_profile_consented_at: (Time.current if consented))
  end

  def bet_score(user, match, points, pool: create(:bolao_pool, championship: match.championship))
    prediction = create(:bolao_prediction, user:, match:, pool:)
    create(:bolao_prediction_score, prediction:, points:)
  end

  def lineup_points(user, points, captain_points: 0, in_championship: championship)
    match = create(:match, championship: in_championship, round: 1)
    captain = create(:player, position: 'ATA')
    other = create(:player, position: 'MEI')
    create(:cartola_player_score, player: captain, match:, points: captain_points)
    create(:cartola_player_score, player: other, match:, points:)
    create(:cartola_lineup, squad: create(:cartola_squad, user:), championship: in_championship,
                            players: [captain, other], captain:)
  end

  describe '.bolao' do
    it "sums each user's best kept score per match, counting a match once across pools" do
      ana = fan('Ana Maria Souza')
      bia = fan('Bia Lima')
      first, second = create_list(:match, 2, championship:)
      bet_score(ana, first, 10)
      bet_score(ana, first, 5)
      bet_score(ana, second, 5)
      bet_score(bia, first, 10)
      bet_score(bia, second, 10).discard
      bet_score(bia, create(:match), 10)

      rows = described_class.bolao(championship)

      expect(rows.map { |row| [row.position, row.user_name, row.points] }).to eq([[1, 'Ana S.', 15], [2, 'Bia L.', 10]])
    end

    it 'ignores scores of discarded predictions' do
      ana = fan('Ana')
      bet_score(ana, create(:match, championship:), 10).prediction.discard

      expect(described_class.bolao(championship)).to be_empty
    end
  end

  describe '.esquadrao' do
    it "ranks the lineups' points with the captain twice" do
      lineup_points(fan('Caio Prado'), 3, captain_points: 4)
      lineup_points(fan('Davi Rocha'), 10)
      lineup_points(fan('Eva Reis'), 50, in_championship: create(:championship))

      rows = described_class.esquadrao(championship)

      expect(rows.map do |row|
        [row.position, row.user_name, row.points]
      end).to eq([[1, 'Caio P.', 11], [2, 'Davi R.', 10]])
    end
  end

  describe '.top' do
    it 'returns both rankings per championship, limited, with shared positions and public names only' do
      other = create(:championship)
      match = create(:match, championship:)
      users = [fan('Ana Souza'), fan('Bia Lima'), fan('Caio Prado', consented: false), fan('Davi Rocha')]
      users.zip([9, 9, 7, 1]).each { |user, points| bet_score(user, match, points) }

      result = described_class.top([championship, other])

      expect(result.keys).to eq([championship.id, other.id])
      expect(result[championship.id][:bolao].map { |row| [row.position, row.user_name] })
        .to eq([[1, 'Ana S.'], [1, 'Bia L.'], [3, 'Participante']])
      expect(result[other.id]).to eq(bolao: [], esquadrao: [])
    end

    it 'runs a fixed number of queries whatever the number of championships' do
      championships = create_list(:championship, 3)
      championships.each do |each_championship|
        bet_score(fan('Ana'), create(:match, championship: each_championship), 3)
      end

      queries = count_queries { described_class.top(championships) }
      expect(count_queries { described_class.top(championships.first(1)) }).to eq(queries)
    end
  end

  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end
end
