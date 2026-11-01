require 'rails_helper'

RSpec.describe Core::Championship do
  it 'is valid with name, season and external_id' do
    expect(build(:championship)).to be_valid
  end

  it 'keeps the season within 1900..2100' do
    expect(build(:championship, season: 1899)).not_to be_valid
  end

  describe 'visibility scopes' do
    let!(:public_championship) { create(:championship) }
    let!(:private_championship) { create(:championship, private: true) }

    it 'publicly_visible returns only championships with private: false' do
      expect(described_class.publicly_visible).to contain_exactly(public_championship)
    end

    it 'private_only returns only championships with private: true' do
      expect(described_class.private_only).to contain_exactly(private_championship)
    end
  end
end
