require 'rails_helper'

RSpec.describe Cartola::Lineup do
  let(:championship) { create(:championship) }

  def players_for(goalkeepers: 1, defenders: 2, midfielders: 3, forwards: 3)
    { 'GOL' => goalkeepers, 'ZAG' => defenders, 'MEI' => midfielders, 'ATA' => forwards }.flat_map do |position, count|
      create_list(:player, count, position:)
    end
  end

  def lineup_with(players, formation: '4-3-3')
    build(:cartola_lineup, championship:, formation:, players:)
  end

  it 'belongs to a squad and a championship and lists its players' do
    keeper = create(:player, position: 'GOL')
    lineup = create(:cartola_lineup, championship:, include_players: [keeper])

    expect(lineup.reload.players.size).to eq(9)
    expect(lineup.players).to include(keeper)
    expect(lineup.squad.user).to be_a(Core::User)
    expect(lineup.championship).to eq(championship)
  end

  it 'allows one lineup per squad, championship and round' do
    lineup = create(:cartola_lineup, championship:, round: 3)

    expect(build(:cartola_lineup, squad: lineup.squad, championship:, round: 3)).not_to be_valid
    expect(build(:cartola_lineup, squad: lineup.squad, round: 3)).to be_valid
    expect { build(:cartola_lineup, squad: lineup.squad, championship:, round: 3).save!(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'only accepts rounds 1 to 38' do
    expect(build(:cartola_lineup, round: 39)).not_to be_valid
    expect { create(:cartola_lineup).update_columns(round: 0) }
      .to raise_error(ActiveRecord::StatementInvalid, /cartola_lineups_round_range/)
  end

  it 'does not list the same player twice' do
    lineup = create(:cartola_lineup)

    player = lineup.players.first
    expect { Cartola::LineupPlayer.new(lineup:, player:, position: player.slot).save!(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'stores the slot each player fills, mapped from the player position' do
    lateral = create(:player, position: 'LAT')
    lineup = create(:cartola_lineup, championship:, include_players: [lateral])

    expect(lineup.lineup_players.find_by(player: lateral).position).to eq('defender')
    expect(lineup.lineup_players.map(&:position).tally)
      .to eq('goalkeeper' => 1, 'defender' => 2, 'midfielder' => 3, 'forward' => 3)
  end

  describe 'championship limits' do
    it 'accepts a lineup at the limits (1 goalkeeper, 2 defenders, 3 midfielders, 3 forwards by default)' do
      expect(lineup_with(players_for)).to be_valid
    end

    it 'accepts fewer players than the limits' do
      expect(lineup_with(players_for(defenders: 1, forwards: 0))).to be_valid
    end

    it 'rejects a lineup without players' do
      lineup = lineup_with([])

      expect(lineup).not_to be_valid
      expect(lineup.errors[:players].join).to include('pelo menos um jogador')
    end

    it 'rejects more players in a position than the championship allows' do
      lineup = lineup_with(players_for(goalkeepers: 2, defenders: 3))

      expect(lineup).not_to be_valid
      expect(lineup.errors[:players]).to contain_exactly(
        'têm 2 goleiros; o limite do campeonato é 1', 'têm 3 defensores; o limite do campeonato é 2'
      )
    end

    it 'counts laterals and center-backs together as defenders' do
      players = players_for(defenders: 1) + [create(:player, position: 'LAT'), create(:player, position: 'LAT')]
      lineup = lineup_with(players)

      expect(lineup).not_to be_valid
      expect(lineup.errors[:players]).to contain_exactly('têm 3 defensores; o limite do campeonato é 2')
    end

    it 'follows limits changed on the championship' do
      championship.update!(cartola_defender_limit: 4, cartola_forward_limit: 2)

      expect(lineup_with(players_for(defenders: 4, forwards: 2))).to be_valid
      expect(lineup_with(players_for(defenders: 4, forwards: 3))).not_to be_valid
    end

    it 'rejects a formation outside the presets' do
      lineup = lineup_with(players_for, formation: '2-4-4')

      expect(lineup).not_to be_valid
      expect(lineup.errors[:formation]).to be_present
    end

    it 'uses the formation only to lay out the pitch, capped by the limits' do
      expect(lineup_with(players_for, formation: '5-4-1').slots)
        .to eq(goalkeeper: 1, defender: 2, midfielder: 3, forward: 1)
    end
  end

  describe '#assign_players' do
    it 'replaces the players on save, keeping the ones still selected' do
      lineup = create(:cartola_lineup)
      kept = lineup.players.to_a
      substitute = create(:player, position: kept.last.position)

      lineup.assign_players(kept[0..7] + [substitute])
      lineup.save!

      expect(lineup.reload.players).to match_array(kept[0..7] + [substitute])
    end
  end
end
