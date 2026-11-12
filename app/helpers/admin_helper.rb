module AdminHelper
  def scoring_path(page, **params) = public_send("#{active_admin_namespace.name}_#{page}_path", **params)

  def scoring_url(page, **params) = public_send("#{active_admin_namespace.name}_#{page}_url", **params)

  def scoring_match_path(match) = public_send("#{active_admin_namespace.name}_match_path", match)

  def scoring_admin_namespace? = active_admin_namespace.name.to_sym == :admin
  ADMIN_LABEL_CLASSES = 'mb-1 block text-sm font-body font-semibold text-ink'.freeze
  ADMIN_FIELD_STATE_CLASSES = 'focus:border-ink focus:ring-2 focus:ring-ink disabled:cursor-not-allowed ' \
                              'disabled:bg-rule/40 disabled:text-graphite'.freeze
  ADMIN_INPUT_CLASSES = 'block min-h-10 w-full rounded-md border border-graphite/70 bg-white px-3 py-2 text-sm ' \
                        "font-body text-ink tabular-nums #{ADMIN_FIELD_STATE_CLASSES}".freeze
  ADMIN_CHOICE_INPUT_CLASSES = 'mr-2 h-5 w-5 cursor-pointer rounded align-middle text-pitch focus:ring-2'.freeze
  ADMIN_COMPACT_INPUT_CLASSES = 'min-h-10 w-12 rounded-md border border-graphite/70 bg-white px-1 py-1 text-center ' \
                                "text-sm font-body tabular-nums text-ink #{ADMIN_FIELD_STATE_CLASSES}".freeze
  ADMIN_BUTTON_BASE_CLASSES = 'inline-flex min-h-10 cursor-pointer items-center justify-center rounded-md px-3 py-2 ' \
                              'text-sm font-body font-semibold no-underline focus:outline-hidden ' \
                              'focus-visible:ring-2 focus-visible:ring-ink focus-visible:ring-offset-2 ' \
                              'disabled:cursor-not-allowed disabled:opacity-60'.freeze
  ADMIN_BUTTON_CLASSES = "#{ADMIN_BUTTON_BASE_CLASSES} bg-cartola text-ink hover:bg-cartola/90".freeze
  ADMIN_SECONDARY_BUTTON_CLASSES = "#{ADMIN_BUTTON_BASE_CLASSES} border border-graphite/70 bg-white text-ink " \
                                   'hover:bg-paper'.freeze
  ADMIN_DANGER_BUTTON_CLASSES = "#{ADMIN_BUTTON_BASE_CLASSES} bg-loss-solid text-paper hover:bg-loss-solid/90".freeze
  ADMIN_TAB_CLASSES = "#{ADMIN_BUTTON_BASE_CLASSES} border aria-[selected=true]:border-cartola " \
                      'aria-[selected=true]:bg-cartola aria-[selected=false]:border-graphite/70 ' \
                      'aria-[selected=false]:bg-white text-ink aria-[selected=false]:hover:bg-paper'.freeze
  ADMIN_STEPPER_CLASSES = 'inline-flex h-10 w-10 shrink-0 cursor-pointer items-center justify-center rounded-md ' \
                          'border border-graphite/70 bg-white font-bold text-ink hover:bg-paper focus:outline-hidden ' \
                          'focus-visible:ring-2 focus-visible:ring-ink disabled:cursor-not-allowed ' \
                          'disabled:border-rule disabled:bg-rule/40 disabled:text-graphite'.freeze
  ADMIN_MUTED_TEXT_CLASSES = 'text-sm font-body text-graphite'.freeze
  # `loss` is already a ≤15% tint in @theme — use as background, ink text/border.
  ADMIN_ALERT_CLASSES = 'rounded-md border-l-4 border-ink bg-loss px-4 py-3 text-sm font-body text-ink'.freeze

  def admin_score(match)
    [match.home_score, match.away_score].map { |goals| goals.nil? ? '–' : goals }.join(' × ')
  end

  def admin_match_status_badge(match, label: nil)
    status = match.status.to_s
    return status_tag(match.status) unless Ui::StatusBadgeComponent::STYLES.key?(status.to_sym)

    render Ui::StatusBadgeComponent.new(status:, label:)
  end

  def admin_match_option(match)
    [match.match_date&.strftime('%d/%m %H:%M'), match, admin_match_status_label(match.status), admin_score(match)]
      .join(' · ')
  end

  def admin_auditable_link(log)
    return unless log.auditable_type

    label = "#{log.auditable_type} ##{log.auditable_id}"
    log.auditable_type == 'Core::Match' ? link_to(label, admin_match_path(log.auditable_id)) : label
  end
end
