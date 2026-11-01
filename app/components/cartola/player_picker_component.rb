module Cartola
  class PlayerPickerComponent < Ui::BaseComponent
    POSITION_LABELS = { 'GOL' => 'Goleiros', 'LAT' => 'Laterais', 'ZAG' => 'Zagueiros', 'MEI' => 'Meias',
                        'ATA' => 'Atacantes' }.freeze

    attr_reader :players, :selected_ids, :prices

    # prices: { player_id => value } (Cartola::PlayerValue.prices_for).
    def initialize(players: nil, selected_ids: [], prices: {}, state: :default)
      super(state:)
      @players = players
      @selected_ids = selected_ids.to_set
      @prices = prices
      require_in_default_state!(:players, players)
    end

    private

    def list? = players.present? && (default? || error?)

    def players_by_position = players.group_by(&:position)

    def selected?(player) = selected_ids.include?(player.id)

    def price(player) = prices[player.id] && format('C$ %.2f', prices[player.id])
  end
end
