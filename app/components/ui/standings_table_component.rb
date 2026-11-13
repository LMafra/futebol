module Ui
  class StandingsTableComponent < BaseComponent
    # change: places gained (+) or lost (-) against another table; nil hides the column.
    # team: the Core::Team, for its crest; without it the short name stands in.
    Row = Data.define(:position, :team_name, :short_name, :played, :wins, :draws, :losses, :goal_difference,
                      :points, :form, :change, :team) do
      def initialize(form: [], change: nil, team: nil, **) = super
    end

    FORM_GLYPHS = {
      'V' => { tint: 'bg-win', label: 'Vitória' },
      'E' => { tint: 'bg-draw', label: 'Empate' },
      'D' => { tint: 'bg-loss', label: 'Derrota' }
    }.freeze

    # Brasileirão bands (ADR 0003 §4); Z4 is always the last four.
    ZONES = {
      title: { label: 'Título', border: 'border-cartola' },
      g4: { label: 'G4', border: 'border-pitch' },
      g6: { label: 'G6', border: 'border-graphite' },
      z4: { label: 'Z4', border: 'border-ink' }
    }.freeze

    SKELETON_ROWS = 10

    attr_reader :rows, :log_path, :empty_message

    def initialize(rows: [], state: :default, log_path: nil, zones: false, empty_message: 'Rodada ainda não pontuada')
      super(state:)
      @rows = rows.map { |row| row.is_a?(Hash) ? Row.new(**row) : row }
      @log_path = log_path
      @zones = zones
      @empty_message = empty_message
    end

    private

    def rendered_state = default? && rows.empty? ? :empty : state

    def leader?(row) = row.position == 1

    def changes? = rows.any? { |row| !row.change.nil? }

    def zone(row)
      return unless @zones

      case row.position
      when 1 then :title
      when 2..4 then :g4
      when 5..6 then :g6
      when (rows.size - 3)..rows.size then :z4 if rows.size >= 10
      end
    end

    def position_classes(row)
      zone = zone(row)
      return "border-l-4 #{ZONES.dig(zone, :border)}" if zone
      return 'border-l-4 border-cartola' if leader?(row)

      ''
    end

    def goal_difference(value) = value.positive? ? "+#{value}" : value.to_s

    def change_glyph(change)
      text, tint, label = if change.positive? then ["▲#{change}", 'bg-win', "Subiu #{change}"]
                          elsif change.negative? then ["▼#{-change}", 'bg-loss', "Caiu #{-change}"]
                          else ['=', 'bg-rule', 'Manteve a posição']
                          end
      tag.span(class: "inline-flex min-w-8 justify-center rounded-sm px-1 #{tint} text-xs font-bold text-ink",
               title: label, data: { role: 'position-change' }) { glyph_with_label(text, label) }
    end

    def form_glyph(result)
      glyph = FORM_GLYPHS.fetch(result)
      tag.span(class: "inline-flex size-6 items-center justify-center rounded-sm #{glyph[:tint]} " \
                      'text-xs font-bold text-ink',
               title: glyph[:label], data: { role: 'form-glyph' }) { glyph_with_label(result, glyph[:label]) }
    end

    def glyph_with_label(glyph, label) = tag.span(glyph, aria: { hidden: true }) + tag.span(label, class: 'sr-only')
  end
end
