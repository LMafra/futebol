module Cartola
  class PlayerPickerComponent < Ui::BaseComponent
    POSITION_LABELS = { 'GOL' => 'Goleiros', 'LAT' => 'Laterais', 'ZAG' => 'Zagueiros', 'MEI' => 'Meias',
                        'ATA' => 'Atacantes' }.freeze

    attr_reader :players, :selected_ids

    def initialize(players: nil, selected_ids: [], state: :default)
      super(state:)
      @players = players
      @selected_ids = selected_ids.to_set
      require_in_default_state!(:players, players)
    end

    private

    def list? = players.present? && (default? || error?)

    def players_by_position = players.group_by(&:position)

    def selected?(player) = selected_ids.include?(player.id)

    def cost(player) = format('C$ %.2f', player.cost)
  end
end
