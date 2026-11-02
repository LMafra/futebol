module Cartola
  # rows: Cartola::RankingsService::Row; kind: :points or :coins (how the value is shown).
  class RankingTableComponent < Ui::BaseComponent
    attr_reader :rows, :kind

    def initialize(rows: nil, kind: :points, state: :default)
      super(state:)
      @rows = rows
      @kind = kind.to_sym
      require_in_default_state!(:rows, rows)
    end

    private

    def rendered_state = default? && rows.empty? ? :empty : state

    def value_header = kind == :coins ? 'Moedas' : 'Pontos'

    def formatted(value) = kind == :coins ? format('C$ %.2f', value) : format('%.2f', value)

    def player_name(user) = user.name.presence || user.email_address
  end
end
