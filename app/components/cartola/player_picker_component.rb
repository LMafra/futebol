module Cartola
  class PlayerPickerComponent < Ui::BaseComponent
    POSITION_LABELS = { 'GOL' => 'Goleiros', 'LAT' => 'Laterais', 'ZAG' => 'Zagueiros', 'MEI' => 'Meias',
                        'ATA' => 'Atacantes' }.freeze

    attr_reader :players, :selected_ids, :prices, :captain_id, :errors

    # prices: { player_id => value } (Cartola::PlayerValue.prices_for); captain_id: the player marked "C".
    def initialize(players: nil, selected_ids: [], prices: {}, state: :default, **options)
      super(state:)
      @players = players
      @selected_ids = selected_ids.to_set
      @prices = prices
      @captain_id = options[:captain_id]
      @errors = Array(options[:errors])
      require_in_default_state!(:players, players)
    end

    private

    def list? = players.present? && (default? || error?)

    def players_by_position = players.group_by(&:position)

    def selected?(player) = selected_ids.include?(player.id)

    def price(player) = prices[player.id] && helpers.esquadrao_money(prices[player.id])

    def error_messages = errors.presence || ['Revise a escalação: confira os limites por posição e o saldo.']
  end
end
