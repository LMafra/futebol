module EsquadraoMoneyHelper
  def esquadrao_money(value) = Cartola::Money.format(value)
end
