require 'rails_helper'

RSpec.describe Core::Championship do
  it 'is valid with name, season and external_id' do
    expect(build(:championship)).to be_valid
  end

  it 'keeps the season within 1900..2100' do
    expect(build(:championship, season: 1899)).not_to be_valid
  end
end
