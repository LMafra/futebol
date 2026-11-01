require 'rails_helper'

RSpec.describe Core::MatchPolicy do
  it { expect(Pundit.policy(nil, Core::Match.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy', allowed_for_admin: %i[index? show?],
                                          extra_admin_actions: %i[preview? finalize? revert?]
end
