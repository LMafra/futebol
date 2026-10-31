require 'rails_helper'

RSpec.describe 'db/seeds.rb' do
  let(:models) { [Core::Team, Core::Player, Core::Championship, Core::Match, Core::User] }

  def counts = models.to_h { |model| [model.name, model.count] }

  it 'is idempotent when loaded twice in a row' do
    expect { Rails.application.load_seed }.to output(/seeds ok/).to_stdout

    after_first_load = counts
    expect(after_first_load.values).to all(be_positive)

    expect { Rails.application.load_seed }.to output(/seeds ok/).to_stdout
    expect(counts).to eq(after_first_load)
  end

  it 'links each match to two distinct seeded teams' do
    expect { Rails.application.load_seed }.to output.to_stdout

    Core::Match.find_each { |match| expect(match.home_team).not_to eq(match.away_team) }
  end
end
