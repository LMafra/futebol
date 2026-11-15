module Ui
  # The reasons behind the point deductions of a table: one line per team with a deduction.
  #   rows: objects with deduction, deduction_reasons and team_name or name (standings or leaderboard rows).
  class PointDeductionNotesComponent < BaseComponent
    def initialize(rows:)
      super()
      @rows = rows.select { |row| row.deduction.to_i.positive? }
    end

    def render? = @rows.any?

    def call
      tag.ul(class: 'mt-2 flex flex-col gap-1 text-sm text-graphite', aria: { label: 'Deduções de pontos' },
             data: { role: 'deduction-notes' }) do
        safe_join(@rows.map { |row| note(row) })
      end
    end

    private

    def note(row)
      name = row.respond_to?(:team_name) ? row.team_name : row.name
      lost = "#{name}: −#{row.deduction} #{'ponto'.pluralize(row.deduction)}"
      tag.li(data: { role: 'deduction-note' }) do
        safe_join([tag.span(lost, class: 'font-semibold text-ink'), " (#{row.deduction_reasons.join('; ')})"])
      end
    end
  end
end
