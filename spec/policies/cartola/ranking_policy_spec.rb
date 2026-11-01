require 'rails_helper'

RSpec.describe Cartola::RankingPolicy do
  subject(:policy) { described_class }

  permissions :show? do
    it('grants any signed-in user') { expect(policy).to permit(build(:user), :ranking) }
    it('denies visitors') { expect(policy).not_to permit(nil, :ranking) }
  end
end
