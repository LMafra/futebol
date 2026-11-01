require 'rails_helper'

RSpec.describe Cartola::Lineup do
  def players_for(goalkeepers: 1, defenders: 4, midfielders: 3, attackers: 3, cost: 5)
    { 'GOL' => goalkeepers, 'ZAG' => defenders, 'MEI' => midfielders, 'ATA' => attackers }.flat_map do |position, count|
      create_list(:player, count, position:, cost:)
    end
  end

  def lineup_with(players, formation: '4-3-3')
    build(:cartola_lineup, formation:, players:)
  end

  it 'belongs to a squad and lists its players' do
    keeper = create(:player, position: 'GOL')
    lineup = create(:cartola_lineup, include_players: [keeper])

    expect(lineup.reload.players.size).to eq(11)
    expect(lineup.players).to include(keeper)
    expect(lineup.squad.user).to be_a(Core::User)
  end

  it 'allows one lineup per squad and round' do
    lineup = create(:cartola_lineup, round: 3)

    expect(build(:cartola_lineup, squad: lineup.squad, round: 3)).not_to be_valid
    expect { build(:cartola_lineup, squad: lineup.squad, round: 3).save!(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'only accepts rounds 1 to 38' do
    expect(build(:cartola_lineup, round: 39)).not_to be_valid
    expect { create(:cartola_lineup).update_columns(round: 0) }
      .to raise_error(ActiveRecord::StatementInvalid, /cartola_lineups_round_range/)
  end

  it 'does not list the same player twice' do
    lineup = create(:cartola_lineup)

    expect { Cartola::LineupPlayer.new(lineup:, player: lineup.players.first).save!(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe 'validations' do
    it 'accepts 11 players that match the formation' do
      expect(lineup_with(players_for)).to be_valid
    end

    it 'rejects a lineup without exactly 11 players' do
      [players_for.first(10), players_for + [create(:player, position: 'ATA')]].each do |players|
        lineup = lineup_with(players)

        expect(lineup).not_to be_valid
        expect(lineup.errors[:players].join).to include('11 jogadores')
      end
    end

    it 'rejects a formation outside the list' do
      lineup = lineup_with(players_for, formation: '2-4-4')

      expect(lineup).not_to be_valid
      expect(lineup.errors[:formation]).to be_present
    end

    it 'rejects positions that do not match the formation' do
      lineup = lineup_with(players_for(defenders: 3, attackers: 4))

      expect(lineup).not_to be_valid
      expect(lineup.errors[:players].join).to include('4-3-3')
    end

    it 'accepts a lineup that costs exactly the budget' do
      players = players_for(cost: 9)
      players.first.update!(cost: 10)

      expect(lineup_with(players).total_cost).to eq(100)
      expect(lineup_with(players)).to be_valid
    end

    it 'rejects a lineup over the budget' do
      lineup = lineup_with(players_for(cost: 9.1))

      expect(lineup.total_cost).to be > 100
      expect(lineup).not_to be_valid
      expect(lineup.errors[:players].join).to include('orçamento')
    end
  end

  describe '#assign_players' do
    it 'replaces the players on save, keeping the ones still selected' do
      lineup = create(:cartola_lineup)
      kept = lineup.players.to_a
      substitute = create(:player, position: kept.last.position)

      lineup.assign_players(kept[0..9] + [substitute])
      lineup.save!

      expect(lineup.reload.players).to match_array(kept[0..9] + [substitute])
    end
  end
end
