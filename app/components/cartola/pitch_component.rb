module Cartola
  class PitchComponent < Ui::BaseComponent
    # Top to bottom, as seen on TV: attack first, goalkeeper last.
    LINES = { attack: 'Ataque', midfield: 'Meio', defense: 'Defesa', goalkeeper: 'Gol' }.freeze

    attr_reader :lineup

    def initialize(lineup: nil, state: :default)
      super(state:)
      @lineup = lineup
      require_in_default_state!(:lineup, lineup)
    end

    private

    def players_on(line) = lineup.players_by_line.fetch(line, []).sort_by(&:name)

    def cost(player) = format('C$ %.2f', player.cost)
  end
end
