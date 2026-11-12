require 'rails_helper'

RSpec.describe Gestor::Core::MatchPolicy do
  subject(:policy) { described_class }

  let(:manager) { create(:user, :manager) }
  let(:other_manager) { create(:user, :manager) }
  let(:regular_user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:own_championship) { create(:championship, manager:) }
  let(:foreign_championship) { create(:championship, manager: other_manager) }
  let(:home_team) { create(:team) }
  let(:away_team) { create(:team) }
  let(:own_match) do
    create(:match, championship: own_championship, home_team:, away_team:, status: 'live', match_date: 1.hour.ago)
  end
  let(:foreign_match) do
    create(:match, championship: foreign_championship, home_team:, away_team:, status: 'live', match_date: 1.hour.ago)
  end

  %i[record_scouts? finalize? revert?].each do |action|
    permissions action do
      it('libera o admin') { expect(policy).to permit(admin, own_match) }
      it('libera o gestor dono do campeonato') { expect(policy).to permit(manager, own_match) }
      it('libera o gestor dono de outro campeonato na própria partida') {
        expect(policy).to permit(other_manager, foreign_match)
      }
      it('nega gestor alheio') { expect(policy).not_to permit(other_manager, own_match) }
      it('nega torcedor') { expect(policy).not_to permit(regular_user, own_match) }
      it('nega visitante') { expect(policy).not_to permit(nil, own_match) }
    end
  end

  permissions :preview? do
    it('libera o admin') { expect(policy).to permit(admin, own_match) }
    it('nega o gestor dono') { expect(policy).not_to permit(manager, own_match) }
    it('nega torcedor') { expect(policy).not_to permit(regular_user, own_match) }
  end
end
