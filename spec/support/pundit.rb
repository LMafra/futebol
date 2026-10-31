require 'pundit/rspec'

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/policies/}) { |metadata| metadata[:type] ||= :policy }
end

ADMIN_POLICY_ACTIONS = %i[index? show? create? new? update? edit? destroy?].freeze

# allowed_for_admin: actions an admin may perform; everything else in ADMIN_POLICY_ACTIONS is denied to everyone.
RSpec.shared_examples 'an admin-only policy' do |allowed_for_admin: ADMIN_POLICY_ACTIONS|
  subject(:policy) { described_class }

  let(:record) { Object.new }
  let(:admin) { build_stubbed(:user, :admin) }
  let(:regular_user) { build_stubbed(:user) }

  allowed_for_admin.each do |action|
    permissions action do
      it('grants an admin') { expect(policy).to permit(admin, record) }
      it('denies a regular user') { expect(policy).not_to permit(regular_user, record) }
      it('denies an anonymous visitor') { expect(policy).not_to permit(nil, record) }
    end
  end

  (ADMIN_POLICY_ACTIONS - allowed_for_admin).each do |action|
    permissions action do
      it('denies even an admin') { expect(policy).not_to permit(admin, record) }
      it('denies a regular user') { expect(policy).not_to permit(regular_user, record) }
    end
  end

  describe 'Scope' do
    let(:scope) { Core::Match.all }

    def resolve(user) = described_class::Scope.new(user, scope).resolve

    it 'resolves everything for an admin' do
      expect(resolve(admin).to_sql).to eq(scope.to_sql)
    end

    it 'resolves nothing for a regular user or an anonymous visitor' do
      create(:match)

      expect(resolve(regular_user)).to be_empty
      expect(resolve(nil)).to be_empty
    end
  end
end
