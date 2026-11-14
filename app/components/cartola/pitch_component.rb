module Cartola
  class PitchComponent < Ui::BaseComponent
    # Top to bottom, as seen on TV: attack first, goalkeeper last.
    SLOTS = { forward: 'Ataque', midfielder: 'Meio', defender: 'Defesa', goalkeeper: 'Gol' }.freeze

    attr_reader :lineup, :prices, :points

    # prices: { player_id => value } (Cartola::PlayerValue.prices_for); players without one show no price.
    # points: { player_id => points counted in the round } (Participantes › Esquadrão); same rule.
    def initialize(lineup: nil, prices: {}, points: {}, state: :default)
      super(state:)
      @lineup = lineup
      @prices = prices
      @points = points
      require_in_default_state!(:lineup, lineup)
    end

    private

    def players_on(slot) = lineup.players_by_slot.fetch(slot, []).sort_by(&:name)

    def open_slots(slot) = [lineup.slots.fetch(slot) - players_on(slot).size, 0].max

    def captain?(player) = player == lineup.captain

    def price(player) = prices[player.id] && format('C$ %.2f', prices[player.id])

    def points_label(player) = points[player.id] && format('%.2f pts', points[player.id])
  end
end
