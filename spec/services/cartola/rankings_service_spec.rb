require 'rails_helper'

RSpec.describe Cartola::RankingsService do
  let(:championship) { create(:championship) }

  def lineup_for(name, players, round: 1, in_championship: championship)
    squad = create(:cartola_squad, user: create(:user, name:))
    create(:cartola_lineup, squad:, championship: in_championship, round:, players:)
  end

  def round_match(round) = create(:match, championship:, round:)

  describe '.points' do
    it "adds up the kept points of each lineup's players in the matches of its round, best first" do
      striker = create(:player, position: 'ATA')
      keeper = create(:player, position: 'GOL')
      midfielder = create(:player, position: 'MEI')
      first_round = round_match(1)
      second_round = round_match(2)
      create(:cartola_player_score, player: striker, match: first_round, points: 10)
      create(:cartola_player_score, player: striker, match: second_round, points: 4)
      create(:cartola_player_score, player: keeper, match: first_round, points: 3)
      create(:cartola_player_score, player: midfielder, match: first_round, points: 50).discard
      lineup_for('Ana', [striker, keeper])
      lineup_for('Ana 2', [striker], round: 2)
      lineup_for('Bia', [midfielder])

      rows = described_class.points(championship)

      expect(rows.map { |row| [row.position, row.user.name, row.value] })
        .to eq([[1, 'Ana', 13], [2, 'Ana 2', 4], [3, 'Bia', 0]])
    end

    it 'sums every round of the same user and ignores other championships' do
      player = create(:player, position: 'ATA')
      create(:cartola_player_score, player:, match: round_match(1), points: 7)
      create(:cartola_player_score, player:, match: round_match(2), points: 5)
      lineup = lineup_for('Ana', [player])
      create(:cartola_lineup, squad: lineup.squad, championship:, round: 2, players: [player])
      lineup_for('Caio', [player], in_championship: create(:championship))

      rows = described_class.points(championship)

      expect(rows.map { |row| [row.user.name, row.value] }).to eq([['Ana', 12]])
    end

    it 'gives tied users the same position' do
      player = create(:player, position: 'ATA')
      create(:cartola_player_score, player:, match: round_match(1), points: 5)
      %w[Bia Ana].each { |name| lineup_for(name, [player]) }
      lineup_for('Caio', [create(:player, position: 'GOL')])

      expect(described_class.points(championship).map { |row| [row.position, row.user.name] })
        .to eq([[1, 'Ana'], [1, 'Bia'], [3, 'Caio']])
    end
  end

  describe '.coins' do
    it 'ranks the wallets of the championship by balance' do
      create(:cartola_wallet, championship:, balance: 80, user: create(:user, name: 'Ana'))
      create(:cartola_wallet, championship:, balance: 120.5, user: create(:user, name: 'Bia'))
      create(:cartola_wallet, balance: 999)

      rows = described_class.coins(championship)

      expect(rows.map { |row| [row.position, row.user.name, row.value] })
        .to eq([[1, 'Bia', BigDecimal('120.5')], [2, 'Ana', 80]])
    end
  end
end
