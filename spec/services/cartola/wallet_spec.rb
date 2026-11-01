require 'rails_helper'

RSpec.describe Cartola::WalletService do
  let(:championship) { create(:championship, cartola_initial_budget: 50, cartola_base_player_value: 4) }
  let(:squad) { create(:cartola_squad) }
  let(:user) { squad.user }

  def new_lineup(players, round: 1)
    Cartola::Lineup.new(squad:, championship:, round:, formation: '4-3-3').tap do |lineup|
      lineup.assign_players(players)
      lineup.assign_captain(players.first&.id)
    end
  end

  def wallet = Cartola::Wallet.find_by!(user:, championship:)

  describe Cartola::Wallet do
    it 'opens once per user and championship with the initial budget' do
      wallet = described_class.for(user:, championship:)

      expect(wallet.balance).to eq(50)
      expect(described_class.for(user:, championship:)).to eq(wallet)
      expect { described_class.create!(user:, championship:, balance: 1) }.to raise_error(ActiveRecord::RecordInvalid)
      expect { described_class.new(user:, championship:, balance: 1).save!(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'never goes negative' do
      wallet = described_class.for(user:, championship:)

      expect { wallet.update_columns(balance: -1) }
        .to raise_error(ActiveRecord::StatementInvalid, /cartola_wallets_balance_non_negative/)
    end
  end

  describe '.save' do
    it "debits the players' base values, using the championship default for players without one" do
      players = [create(:player, position: 'GOL', base_value: 10), create(:player, position: 'ATA')]

      expect(described_class.save(new_lineup(players))).to be(true)

      expect(wallet.balance).to eq(50 - 10 - 4)
    end

    it 'charges the current value once the player was re-priced' do
      player = create(:player, position: 'MEI', base_value: 10)
      create(:cartola_player_value, player:, championship:, value: 12.5)

      described_class.save(new_lineup([player]))

      expect(wallet.balance).to eq(37.5)
    end

    it 'charges only the difference when players are swapped' do
      keeper = create(:player, position: 'GOL', base_value: 10)
      striker = create(:player, position: 'ATA', base_value: 6)
      lineup = new_lineup([keeper, striker])
      described_class.save(lineup)
      substitute = create(:player, position: 'ATA', base_value: 9)

      lineup.assign_players([keeper, substitute])
      described_class.save(lineup)

      expect(wallet.balance).to eq(50 - 10 - 9)
    end

    it 'refuses a lineup the balance does not cover, without touching it' do
      players = create_list(:player, 3, position: 'MEI', base_value: 20)
      lineup = new_lineup(players)

      expect(described_class.save(lineup)).to be(false)

      expect(lineup).not_to be_persisted
      expect(lineup.errors[:base].join).to include('Saldo insuficiente')
      expect(wallet.balance).to eq(50)
    end

    it 'refuses an invalid lineup without charging' do
      lineup = new_lineup(create_list(:player, 2, position: 'GOL'))

      expect(described_class.save(lineup)).to be(false)
      expect(wallet.balance).to eq(50)
    end

    it 'charges each round lineup separately' do
      described_class.save(new_lineup([create(:player, position: 'GOL', base_value: 10)], round: 1))
      described_class.save(new_lineup([create(:player, position: 'GOL', base_value: 10)], round: 2))

      expect(wallet.balance).to eq(30)
    end
  end

  describe '.destroy' do
    it 'refunds the lineup at current prices and removes it' do
      player = create(:player, position: 'MEI', base_value: 10)
      lineup = new_lineup([player])
      described_class.save(lineup)
      create(:cartola_player_value, player:, championship:, value: 11)

      expect(described_class.destroy(lineup)).to eq(11)

      expect(Cartola::Lineup.exists?(lineup.id)).to be(false)
      expect(wallet.balance).to eq(51)
    end
  end
end
