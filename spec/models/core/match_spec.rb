require 'rails_helper'

RSpec.describe Core::Match do
  it 'is valid with distinct teams, a championship and a match_date' do
    expect(build(:match)).to be_valid
  end

  it 'only takes teams enrolled in its championship' do
    championship = create(:championship)
    enrolled, outsider = create_list(:team, 2)
    championship.championship_teams.create!(team: enrolled)
    match = build(:match, championship:, home_team: enrolled, away_team: outsider)

    expect(match).not_to be_valid
    expect(match.errors[:away_team]).to include('não está inscrito neste campeonato')
    expect(match.errors[:home_team]).to be_empty
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
    expect(build(:match, status: 'cancelled')).not_to be_valid
    expect(described_class::STATUSES).to eq(%w[scheduled live finished scored reverted])
  end

  it 'requires scores_calculated_at when scored and forbids it outside finished/scored' do
    expect(build(:match, status: 'scored', scores_calculated_at: nil)).not_to be_valid
    expect(build(:match, status: 'scored', scores_calculated_at: Time.current)).to be_valid
    expect(build(:match, status: 'finished', scores_calculated_at: Time.current)).to be_valid
    expect(build(:match, status: 'reverted', scores_calculated_at: Time.current)).not_to be_valid
    expect(build(:match, status: 'scheduled', scores_calculated_at: Time.current)).not_to be_valid
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

    it 'blocks reverted matches that keep scores_calculated_at' do
      match = create(:match, status: 'finished', scores_calculated_at: 1.hour.ago)

      expect { match.update_columns(status: 'reverted') }
        .to raise_error(ActiveRecord::StatementInvalid, /matches_timestamp_after_finish/)
    end

    it 'blocks unknown statuses' do
      match = create(:match)

      expect { match.update_columns(status: 'cancelled') }
        .to raise_error(ActiveRecord::StatementInvalid, /matches_status_valid/)
    end

    it 'blocks negative scores' do
      match = create(:match)

      expect { match.update_columns(home_score: -1, away_score: 0) }
        .to raise_error(ActiveRecord::StatementInvalid, /matches_scores_non_negative/)
    end
  end

  describe 'state machine' do
    it 'starts scheduled' do
      expect(described_class.new).to be_scheduled
    end

    it 'goes live only once kickoff has been reached' do
      expect { create(:match, match_date: 1.minute.from_now).start_match! }.to raise_error(AASM::InvalidTransition)

      match = create(:match, match_date: 1.minute.ago)
      match.start_match!

      expect(match.reload).to be_live
    end

    it 'finishes only with both scores present' do
      match = create(:match, status: 'live', match_date: 1.hour.ago)
      expect { match.finish_match! }.to raise_error(AASM::InvalidTransition)

      match.update!(home_score: 2, away_score: 1)
      match.finish_match!

      expect(match.reload).to be_finished
    end

    it 'marks a finished match as scored, stamping scores_calculated_at and scoring_token' do
      match = create(:match, status: 'finished', home_score: 2, away_score: 1)
      token = SecureRandom.uuid

      match.mark_scored!(token)

      expect(match.reload).to have_attributes(status: 'scored', scoring_token: token)
      expect(match.scores_calculated_at).to be_present
    end

    it 'refuses to score a match that already has scores_calculated_at' do
      match = create(:match, status: 'finished', scores_calculated_at: 1.hour.ago)

      expect { match.mark_scored!(SecureRandom.uuid) }.to raise_error(AASM::InvalidTransition)
    end

    it 'reverts a scored match clearing scoring_token and issuing a reversal_token in the same save' do
      match = create(:match, status: 'scored', scores_calculated_at: 1.hour.ago, scoring_token: SecureRandom.uuid)

      match.revert_match!

      expect(match.saved_changes.keys).to include('status', 'scores_calculated_at', 'scoring_token', 'reversal_token')
      expect(match.reload).to have_attributes(status: 'reverted', scores_calculated_at: nil, scoring_token: nil)
      expect(match.reversal_token).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end

    it 'stores the reversal_token handed to revert_match!' do
      match = create(:match, status: 'scored', scores_calculated_at: 1.hour.ago, scoring_token: SecureRandom.uuid)
      token = SecureRandom.uuid

      match.revert_match!(token)

      expect(match.reload).to have_attributes(status: 'reverted', reversal_token: token)
    end

    it 'can be scored again after a revert' do
      match = create(:match, status: 'scored', scores_calculated_at: 1.hour.ago, scoring_token: SecureRandom.uuid)
      match.revert_match!

      match.mark_scored!(SecureRandom.uuid)

      expect(match.reload).to be_scored
    end
  end

  describe '#revert_match!' do
    it 'reverte com scores_calculated_at presente e zera depois' do
      calculated_at = 1.hour.ago.change(usec: 0)
      match = create(:match, status: :finished, scores_calculated_at: calculated_at)
      seen_by_guard = []
      allow(match).to receive(:scores_calculated?).and_wrap_original do |original, *args|
        seen_by_guard << match.scores_calculated_at
        original.call(*args)
      end

      expect { match.revert_match! }.to change { match.reload.status }.from('finished').to('reverted')
      expect(seen_by_guard).to be_present
      expect(seen_by_guard).to all(eq(calculated_at))
      expect(match.reload.scores_calculated_at).to be_nil
    end

    it 'falha o guard se scores_calculated_at for nil' do
      match = create(:match, status: :finished, scores_calculated_at: nil)
      expect { match.revert_match! }.to raise_error(AASM::InvalidTransition)
    end
  end
end
