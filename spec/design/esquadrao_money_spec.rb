require 'rails_helper'

# docs/glossary.md: E$ is the Esquadrão currency, formatted only by Cartola::Money (esquadrao_money in views).
RSpec.describe 'Moeda do Esquadrão' do
  sources = Rails.root.glob('{app,engines/*/app,lib,config/locales,db/seeds}/**/*.{rb,erb,yml}') +
            [Rails.root.join('db/seeds.rb')]
  formatter = Rails.root.join('engines/cartola/app/models/cartola/money.rb')

  it 'never shows the old C$ symbol' do
    offenders = sources.select { |path| File.read(path).include?('C$') }
    expect(offenders.map { |path| path.relative_path_from(Rails.root).to_s }).to be_empty
  end

  it 'formats amounts only in Cartola::Money' do
    offenders = (sources - [formatter]).select { |path| File.read(path).match?(/E\$ ?%/) }
    expect(offenders.map { |path| path.relative_path_from(Rails.root).to_s }).to be_empty
  end
end
