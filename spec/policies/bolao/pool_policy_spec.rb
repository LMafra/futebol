require 'rails_helper'

RSpec.describe Bolao::PoolPolicy do
  it { expect(Pundit.policy(nil, Bolao::Pool.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy'
end
