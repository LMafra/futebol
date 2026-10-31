require 'rails_helper'

RSpec.describe Core::Match do
  it 'is valid with distinct teams, a championship and a match_date' do
    expect(build(:match)).to be_valid
  end

  it 'requires a match_date' do
    expect(build(:match, match_date: nil)).not_to be_valid
  end

  it 'rejects the same team on both sides' do
    team = create(:team)
    match = build(:match, home_team: team, away_team: team)

    expect(match).not_to be_valid
    expect(match.errors[:away_team]).to be_present
  end

  it 'rejects negative scores' do
    expect(build(:match, home_score: -1)).not_to be_valid
  end

  it 'only accepts known statuses' do
    expect(build(:match, status: 'reverted')).not_to be_valid
  end

  it 'requires scores_calculated_at exactly when scored' do
    expect(build(:match, status: 'scored', scores_calculated_at: nil)).not_to be_valid
    expect(build(:match, status: 'finished', scores_calculated_at: Time.current)).not_to be_valid
    expect(build(:match, status: 'scored', scores_calculated_at: Time.current)).to be_valid
  end

  it 'enforces unique external_id' do
    create(:match, external_id: 'br26-r1-fla-pal')

    expect(build(:match, external_id: 'br26-r1-fla-pal')).not_to be_valid
  end

  describe 'database check constraints' do
    it 'blocks identical teams even when validations are skipped' do
      team = create(:team)
      match = build(:match, home_team: team, away_team: team)

      expect { match.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /matches_distinct_teams/)
    end

    it 'blocks scored matches without scores_calculated_at' do
      match = create(:match)

      expect { match.update_columns(status: 'scored') }
        .to raise_error(ActiveRecord::StatementInvalid, /matches_scored_has_timestamp/)
    end

    it 'blocks unknown statuses' do
      match = create(:match)

      expect { match.update_columns(status: 'reverted') }
        .to raise_error(ActiveRecord::StatementInvalid, /matches_status_valid/)
    end

    it 'blocks negative scores' do
      match = create(:match)

      expect { match.update_columns(home_score: -1, away_score: 0) }
        .to raise_error(ActiveRecord::StatementInvalid, /matches_scores_non_negative/)
    end
  end
end
