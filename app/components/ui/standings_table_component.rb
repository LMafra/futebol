module Ui
  class StandingsTableComponent < BaseComponent
    Row = Data.define(:position, :team_name, :short_name, :played, :wins, :draws, :losses, :goal_difference,
                      :points, :form) do
      def initialize(form: [], **) = super
    end

    FORM_GLYPHS = {
      'V' => { tint: 'bg-win', label: 'Vitória' },
      'E' => { tint: 'bg-draw', label: 'Empate' },
      'D' => { tint: 'bg-loss', label: 'Derrota' }
    }.freeze

    SKELETON_ROWS = 10

    attr_reader :rows, :log_path

    def initialize(rows: [], state: :default, log_path: nil)
      super(state:)
      @rows = rows.map { |row| row.is_a?(Hash) ? Row.new(**row) : row }
      @log_path = log_path
    end

    private

    def rendered_state = default? && rows.empty? ? :empty : state

    def leader?(row) = row.position == 1

    def goal_difference(value) = value.positive? ? "+#{value}" : value.to_s

    def form_glyph(result)
      glyph = FORM_GLYPHS.fetch(result)
      tag.span(result, class: "inline-flex size-6 items-center justify-center rounded-sm #{glyph[:tint]} " \
                              'text-xs font-bold text-ink',
                       title: glyph[:label], aria: { label: glyph[:label] }, data: { role: 'form-glyph' })
    end
  end
end
