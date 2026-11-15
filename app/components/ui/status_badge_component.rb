module Ui
  # Static status chip for match/championship lifecycle — icon + text + color (no pulse).
  class StatusBadgeComponent < BaseComponent
    STYLES = {
      scheduled: 'bg-rule text-ink',
      # cartola fill keeps ≥4.5:1 with ink (critique); research also allows pitch/10.
      live: 'bg-cartola text-ink',
      pending_scouts: 'bg-cartola/15 text-ink',
      finished: 'bg-pitch/10 text-pitch',
      scored: 'bg-pitch text-paper',
      # loss token is already a ≤15% tint (critique Q1) — text stays ink.
      reverted: 'bg-red-50 text-red-800'
    }.freeze

    LABELS = {
      scheduled: 'Agendada',
      live: 'Ao vivo',
      pending_scouts: 'Aguardando lances',
      finished: 'Encerrada',
      scored: 'Pontuada',
      reverted: 'Revertida'
    }.freeze

    # Heroicons-style path `d` attributes (24 viewBox).
    ICONS = {
      scheduled: 'M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z',
      live: 'M15.362 5.214A8.252 8.252 0 0112 21 8.25 8.25 0 016.038 7.048 8.287 8.287 0 009 9.6a8.983 8.983 0 013.361-6.867 8.21 8.21 0 003 2.48z',
      pending_scouts: 'M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z',
      finished: 'M3 3v1.5M3 21v-6m0 0l2.77-.693a9 9 0 016.208.682l.108.054a9 9 0 006.086.71l3.114-.732a48.524 48.524 0 01-.005-10.499l-3.11.732a9 9 0 01-6.085-.711l-.108-.054a9 9 0 00-6.208-.682L3 4.5M3 15V4.5',
      scored: 'M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
      reverted: 'M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z'
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

    def icon_path = ICONS.fetch(status)

    def badge_classes
      base = 'inline-flex items-center gap-1 rounded-sm px-2 py-0.5 text-xs font-body ' \
             'font-semibold uppercase tracking-wide'
      "#{base} #{STYLES.fetch(status)}"
    end
  end
end
