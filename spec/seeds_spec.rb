require 'rails_helper'

RSpec.describe 'db/seeds.rb' do
  let(:models) do
    [Core::Team, Core::Player, Core::Championship, Core::Match, Core::User, Bolao::ScoringRule, Cartola::ScoringRule]
  end

  def counts = models.to_h { |model| [model.name, model.count] }

  it 'is idempotent when loaded twice in a row' do
    expect { Rails.application.load_seed }.to output(/seeds ok/).to_stdout

    after_first_load = counts
    expect(after_first_load.values).to all(be_positive)

    expect { Rails.application.load_seed }.to output(/seeds ok/).to_stdout
    expect(counts).to eq(after_first_load)
  end

  it 'seeds the global Bolão rule 10/7/5/3 and the default Cartola rule' do
    expect { Rails.application.load_seed }.to output.to_stdout

    expect(Bolao::ScoringRule.for(nil)).to eq(exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3)
    expect(Cartola::ScoringRule.default)
      .to have_attributes(goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)
  end

  it 'links each match to two distinct seeded teams' do
    expect { Rails.application.load_seed }.to output.to_stdout

    Core::Match.find_each { |match| expect(match.home_team).not_to eq(match.away_team) }
  end
end
