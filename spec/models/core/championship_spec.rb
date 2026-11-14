require 'rails_helper'

RSpec.describe Core::Championship do
  it 'is valid with name, season and external_id' do
    expect(build(:championship)).to be_valid
  end

  it 'keeps the season within 1900..2100' do
    expect(build(:championship, season: 1899)).not_to be_valid
  end

  it 'lists its enrolled teams once each' do
    championship = create(:championship)
    first = create(:match, championship:)
    create(:match, championship:, home_team: first.away_team, away_team: first.home_team)
    create(:match)

    expect(championship.teams).to contain_exactly(first.home_team, first.away_team)
  end

  describe 'visibility scopes' do
    let!(:public_championship) { create(:championship) }
    let!(:private_championship) { create(:championship, private: true) }
    let!(:draft_championship) { create(:championship, status: 'draft') }

    it 'publicly_visible returns only published championships with private: false' do
      expect(described_class.publicly_visible).to contain_exactly(public_championship)
    end

    it 'private_only returns only championships with private: true' do
      expect(described_class.private_only).to contain_exactly(private_championship)
    end

    it 'latest ignores drafts' do
      draft_championship.update!(season: 2030)

      expect(described_class.latest).to eq(private_championship)
    end
  end

  describe 'modalidade' do
    it 'defaults to Campo · Masculino · Adulto · Amador, published' do
      championship = create(:championship)

      expect(championship.modality_label).to eq('Campo · Masculino · Adulto · Amador')
      expect(championship).to be_published
    end

    it 'rejects values outside the lists' do
      championship = build(:championship, kind: 'praia', level: 'semi')

      expect(championship).not_to be_valid
      expect(championship.errors.attribute_names).to include(:kind, :level)
    end

    it 'applies the Esquadrão limits of the kind while a draft changes it' do
      championship = create(:championship, status: 'draft')
      championship.update!(kind: 'futsal')

      expect(championship.slice(:cartola_goalkeeper_limit, :cartola_defender_limit, :cartola_midfielder_limit,
                                :cartola_forward_limit).values).to eq([1, 1, 1, 2])
    end

    it 'keeps the limits of a published championship when the kind changes' do
      championship = create(:championship, cartola_forward_limit: 5)
      championship.update!(kind: 'futsal')

      expect(championship.cartola_forward_limit).to eq(5)
    end
  end
end
