module Cartola
  # The Esquadrão currency (E$): prices, wallets, budgets and player values. Every visible amount is formatted here;
  # views use EsquadraoMoneyHelper#esquadrao_money.
  module Money
    SYMBOL = 'E$'.freeze

    def self.format(value) = Kernel.format("#{SYMBOL} %.2f", value)

    # Form label of an amount field: "Valor base (E$)".
    def self.label(text) = "#{text} (#{SYMBOL})"
  end
end
