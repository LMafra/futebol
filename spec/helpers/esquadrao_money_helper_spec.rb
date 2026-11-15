require 'rails_helper'

RSpec.describe EsquadraoMoneyHelper, type: :helper do
  it 'formats Esquadrão amounts in E$ with two decimals' do
    expect(helper.esquadrao_money(12.5)).to eq('E$ 12.50')
    expect(helper.esquadrao_money(BigDecimal('100'))).to eq('E$ 100.00')
  end

  it 'delegates to the single formatter in the cartola engine' do
    expect(helper.esquadrao_money(3)).to eq(Cartola::Money.format(3))
  end

  it 'labels amount fields with the symbol' do
    expect(Cartola::Money.label('Valor base')).to eq('Valor base (E$)')
  end
end
