module AdminHelper
  def scoring_path(page, **params) = public_send("#{active_admin_namespace.name}_#{page}_path", **params)

  def scoring_url(page, **params) = public_send("#{active_admin_namespace.name}_#{page}_url", **params)

  def scoring_match_path(match) = public_send("#{active_admin_namespace.name}_match_path", match)

  def scoring_admin_namespace? = active_admin_namespace.name.to_sym == :admin
  ADMIN_LABEL_CLASSES = 'mb-1 block text-sm font-body font-semibold text-ink'.freeze
  ADMIN_INPUT_CLASSES = 'block w-full rounded-md border border-rule bg-paper px-3 py-2 text-sm font-body text-ink ' \
                        'tabular-nums focus:border-cartola focus:ring-cartola'.freeze
  ADMIN_BUTTON_CLASSES = 'inline-flex cursor-pointer items-center rounded-md bg-cartola px-3 py-2 ' \
                         'text-sm font-body font-semibold text-ink hover:bg-cartola/90 focus:outline-none ' \
                         'focus:ring-2 focus:ring-cartola'.freeze
  ADMIN_SECONDARY_BUTTON_CLASSES = 'inline-flex cursor-pointer items-center rounded-md border border-rule ' \
                                   'bg-paper px-3 py-2 text-sm font-body font-semibold text-ink ' \
                                   'hover:bg-white focus:outline-none focus:ring-2 focus:ring-rule'.freeze
  ADMIN_DANGER_BUTTON_CLASSES = 'inline-flex cursor-pointer items-center rounded-md border border-ink ' \
                                'bg-loss px-3 py-2 text-sm font-body font-semibold text-ink ' \
                                'hover:bg-loss/80 focus:outline-none focus:ring-2 focus:ring-ink'.freeze
  ADMIN_MUTED_TEXT_CLASSES = 'text-sm font-body text-graphite'.freeze
  # `loss` is already a ≤15% tint in @theme — use as background, ink text/border.
  ADMIN_ALERT_CLASSES = 'rounded-md border-l-4 border-ink bg-loss px-4 py-3 text-sm font-body text-ink'.freeze
  ADMIN_COMPACT_INPUT_CLASSES = 'w-12 rounded-md border border-rule bg-paper px-1 py-1 text-center ' \
                                'text-sm font-body tabular-nums text-ink focus:border-cartola focus:ring-cartola'.freeze

  def admin_score(match)
    [match.home_score, match.away_score].map { |goals| goals.nil? ? '–' : goals }.join(' × ')
  end

  def admin_match_status_badge(match)
    status = match.status.to_s
    status = 'finished' if status == 'scored'
    return status_tag(match.status) unless Ui::StatusBadgeComponent::STYLES.key?(status.to_sym)

    render Ui::StatusBadgeComponent.new(status:)
  end

  def admin_match_option(match)
    "#{match.match_date&.strftime('%d/%m %H:%M')} · #{match} · #{match.status} · #{admin_score(match)}"
  end

  def admin_auditable_link(log)
    return unless log.auditable_type

    label = "#{log.auditable_type} ##{log.auditable_id}"
    log.auditable_type == 'Core::Match' ? link_to(label, admin_match_path(log.auditable_id)) : label
  end
end
