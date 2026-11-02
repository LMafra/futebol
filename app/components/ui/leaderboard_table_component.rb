module Ui
  # A ranking of people or players: position, name and points, plus optional numeric columns before the points.
  #   rows:    objects with position, name and points (Core::ChampionshipRankingsService::Row, ...); an optional
  #            detail (e.g. the team) shows next to the name;
  #   texts:   label (aria), name_header and empty, over TEXTS;
  #   columns: { attribute => [abbreviation, title] } read from each row;
  #   compact: the home card variant, with the header hidden from sight and no extra columns.
  class LeaderboardTableComponent < BaseComponent
    TEXTS = { label: 'Ranking', name_header: 'Participante', empty: 'Ninguém pontuou ainda.' }.freeze
    SKELETON_ROWS = 5

    attr_reader :rows

    def initialize(rows: [], texts: {}, columns: {}, compact: false, state: :default)
      super(state:)
      @rows = rows
      @texts = TEXTS.merge(texts)
      @columns = columns
      @compact = compact
    end

    def compact? = @compact

    def columns = compact? ? {} : @columns

    def text(key) = @texts.fetch(key)

    private

    def rendered_state = default? && rows.empty? ? :empty : state

    def cell_classes = compact? ? 'px-1 py-1' : 'px-2 py-2'

    def skeleton_rows = compact? ? 3 : SKELETON_ROWS

    def points(value) = value.is_a?(Integer) ? value.to_s : format('%.2f', value)
  end
end
