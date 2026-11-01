require 'rails_helper'

RSpec.describe Core::CsvImportPolicy do
  it { expect(Pundit.policy(nil, Core::CsvImport.new)).to be_a(described_class) }

  it_behaves_like 'an admin-only policy', allowed_for_admin: %i[index? show? create? new?],
                                          extra_admin_actions: %i[import?]
end
