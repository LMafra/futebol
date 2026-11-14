module Ui
  # Static status chip for match/championship lifecycle (no pulse — critique Q7).
  class StatusBadgeComponent < BaseComponent
    STYLES = {
      scheduled: 'bg-rule text-ink',
      # cartola is a fill, never text on a light background (≈3:1); ink on cartola is 5.2:1.
      live: 'bg-cartola text-ink',
      finished: 'bg-pitch/10 text-pitch',
      scored: 'bg-pitch text-paper',
      # loss token is already a ≤15% tint (critique Q1) — text stays ink.
      reverted: 'bg-loss text-ink'
    }.freeze

    LABELS = {
      scheduled: 'Agendada',
      live: 'Ao vivo',
      finished: 'Encerrada',
      scored: 'Pontuada',
      reverted: 'Revertida'
    }.freeze

    attr_reader :status

    def initialize(status: :scheduled, label: nil, state: :default)
      super(state:)
      @status = status.to_s.to_sym
      @label = label
      return if STYLES.key?(@status)

      raise ArgumentError, "invalid status #{status.inspect} (expected one of: #{STYLES.keys.join(', ')})"
    end

    def label = @label || LABELS.fetch(status)

    def badge_classes
      base = 'inline-flex items-center rounded-sm px-2 py-0.5 text-xs font-body ' \
             'font-semibold uppercase tracking-wide'
      "#{base} #{STYLES.fetch(status)}"
    end
  end
end
