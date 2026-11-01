module Cartola
  # Buys and sells a lineup's players against the owner's wallet at current prices (PlayerValue.prices_for):
  # saving charges the players added and refunds the ones dropped; destroying refunds the whole lineup.
  # Each round's lineup is its own purchase.
  module WalletService
    # Returns false, with the reason in lineup.errors, when the lineup is invalid or the balance does not cover it.
    def self.save(lineup)
      Lineup.transaction do
        wallet = wallet_for(lineup)
        cost = price_change(lineup)
        next false unless lineup.valid? && affordable?(lineup, cost, wallet)

        wallet.update!(balance: wallet.balance - cost)
        lineup.save!
      end
    end

    # Returns the amount refunded.
    def self.destroy(lineup)
      Lineup.transaction do
        wallet = wallet_for(lineup)
        refund = total(lineup.lineup_players.map(&:player), lineup.championship)
        wallet.update!(balance: wallet.balance + refund)
        lineup.destroy!
        refund
      end
    end

    def self.wallet_for(lineup) = Wallet.for(user: lineup.squad.user, championship: lineup.championship).lock!

    def self.price_change(lineup)
      added, dropped = %i[new_record? marked_for_destruction?].map do |state|
        lineup.lineup_players.select(&state).map(&:player)
      end
      prices = PlayerValue.prices_for(added + dropped, lineup.championship)
      added.sum { |player| prices.fetch(player.id) } - dropped.sum { |player| prices.fetch(player.id) }
    end

    def self.total(players, championship) = PlayerValue.prices_for(players, championship).values.sum

    def self.affordable?(lineup, cost, wallet)
      return true if cost <= wallet.balance

      lineup.errors.add(:base, format('Saldo insuficiente: a escalação custa mais C$ %<cost>.2f e o saldo é ' \
                                      'C$ %<balance>.2f', cost:, balance: wallet.balance))
      false
    end

    private_class_method :wallet_for, :price_change, :total, :affordable?
  end
end
