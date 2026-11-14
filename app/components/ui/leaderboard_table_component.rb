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

    def position_cell(position)
      medal = medal_for(position)
      return position.to_s unless medal

      tag.span(class: 'inline-flex items-center gap-1') do
        safe_join([medal, tag.span(position.to_s)])
      end
    end

    def medal_for(position)
      fill = { 1 => '#E85D04', 2 => '#4A4A45', 3 => '#0B6B3A' }[position]
      return unless fill

      tag.svg(class: 'h-4 w-4', viewBox: '0 0 24 24', aria: { hidden: true },
              data: { role: 'medal', position: }) do
        safe_join([
                    tag.circle(cx: '12', cy: '12', r: '10', fill:),
                    tag.path(d: 'M12 7l1.5 3.5H17l-2.8 2.2L15.5 17 12 14.8 8.5 17l1.3-4.3L7 10.5h3.5L12 7z',
                             fill: '#F4F1EA')
                  ])
      end
    end
  end
end
