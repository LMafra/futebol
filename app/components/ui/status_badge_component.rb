module Ui
  # Static status chip for match/championship lifecycle (no pulse — critique Q7).
  class StatusBadgeComponent < BaseComponent
    STYLES = {
      scheduled: 'bg-rule text-ink',
      live: 'bg-cartola/10 text-cartola',
      finished: 'bg-pitch/10 text-pitch',
      reverted: 'bg-loss/10 text-loss'
    }.freeze

    LABELS = {
      scheduled: 'Agendada',
      live: 'Ao vivo',
      finished: 'Encerrada',
      reverted: 'Revertida'
    }.freeze

    attr_reader :status

    def initialize(status: :scheduled, state: :default)
      super(state:)
      @status = status.to_s.to_sym
      return if STYLES.key?(@status)

      raise ArgumentError, "invalid status #{status.inspect} (expected one of: #{STYLES.keys.join(', ')})"
    end

    def label = LABELS.fetch(status)

    def badge_classes
      base = 'inline-flex items-center rounded-sm px-2 py-0.5 text-xs font-body ' \
             'font-semibold uppercase tracking-wide'
      "#{base} #{STYLES.fetch(status)}"
    end
  end
end
