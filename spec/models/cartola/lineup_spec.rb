require 'rails_helper'

RSpec.describe Cartola::Lineup do
  it 'belongs to a squad and lists its players' do
    players = create_list(:player, 2)
    lineup = create(:cartola_lineup, players:)

    expect(lineup.reload.players).to match_array(players)
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
    player = create(:player)
    lineup = create(:cartola_lineup, players: [player])

    expect { Cartola::LineupPlayer.new(lineup:, player:).save!(validate: false) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
