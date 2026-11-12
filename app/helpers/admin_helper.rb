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

  # Compact Heroicons-style paths for task sidebar sections (no emoji).
  ADMIN_NAV_ICON_PATHS = {
    'Visão geral' => 'M3 9.75L12 3l9 6.75V21a.75.75 0 01-.75.75H3.75A.75.75 0 013 21V9.75z',
    'Painel' => 'M3 9.75L12 3l9 6.75V21a.75.75 0 01-.75.75H3.75A.75.75 0 013 21V9.75z',
    'Dashboard' => 'M3 9.75L12 3l9 6.75V21a.75.75 0 01-.75.75H3.75A.75.75 0 013 21V9.75z',
    'Meus campeonatos' => 'M4.5 5.25h15v13.5h-15zM8.25 9h7.5M8.25 12.75h7.5',
    'Partidas' => 'M12 6v6h4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    'Participantes' => 'M15 19.5a3 3 0 00-6 0M15 8.25a3 3 0 11-6 0 3 3 0 016 0zM19.5 19.5a2.25 2.25 0 00-2.25-2.25',
    'Configurações' => 'M12 15.75a3.75 3.75 0 100-7.5 3.75 3.75 0 000 7.5zM4.5 12h3M16.5 12h3M12 4.5v3M12 16.5v3',
    'Auditoria' => 'M8.25 6.75h7.5v12h-7.5zM10.5 9.75h3M10.5 12.75h3M10.5 15.75h3'
  }.freeze

  def admin_nav_section_icon(label)
    path = ADMIN_NAV_ICON_PATHS[label.to_s]
    return ''.html_safe if path.blank?

    admin_svg_icon(path, 'h-5 w-5 shrink-0')
  end

  # Compact Heroicons-style paths for index row actions (tooltip via title).
  ADMIN_ACTION_ICON_PATHS = {
    view: 'M2.25 12s3.75-6.75 9.75-6.75S21.75 12 21.75 12 18 18.75 12 18.75 2.25 12 2.25 12zM15 12a3 3 0 11-6 0',
    edit: 'M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L6.75 18l-2.685.8.8-2.685 10.997-11.0z',
    delete: 'M6 7.5h12M9.75 7.5V6h4.5v1.5M8.25 7.5l.75 12h6l.75-12',
    preview: 'M3.75 4.5h16.5v12H3.75zM8.25 19.5h7.5',
    finalize: 'M4.5 12.75l6 6 9-13.5',
    scouts: 'M16.5 6.75h-9v10.5h9zM9.75 9.75h4.5M9.75 12.75h4.5M9.75 15.75h3',
    revert: 'M9 15L3 9m0 0l6-6M3 9h12a6 6 0 010 12h-3'
  }.freeze

  def admin_icon_action_link(label, href, icon, **html_options)
    path = ADMIN_ACTION_ICON_PATHS.fetch(icon.to_sym)
    hover = icon.to_sym == :delete ? 'hover:border-ink hover:bg-loss' : 'hover:border-ink hover:bg-paper'
    classes = 'inline-flex h-10 w-10 items-center justify-center rounded-md border border-graphite/70 bg-white ' \
              "text-ink no-underline #{hover} focus:outline-hidden " \
              'focus-visible:ring-2 focus-visible:ring-ink focus-visible:ring-offset-2'
    data = (html_options.delete(:data) || {}).merge(role: 'admin-table-action')
    link_to(href, **html_options, class: classes, title: label, 'aria-label': label, data:) do
      admin_svg_icon(path, 'h-4 w-4')
    end
  end

  def admin_svg_icon(path, css_class)
    tag.svg(class: css_class, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor',
            'stroke-width': '1.5', 'aria-hidden': true) do
      tag.path(d: path, 'stroke-linecap': 'round', 'stroke-linejoin': 'round')
    end
  end

  # Discrete KPI glyphs (no emoji) for status-first dashboard cards.
  ADMIN_KPI_ICON_PATHS = {
    'Campeonatos ativos' => 'M4.5 5.25h15v13.5h-15zM8.25 9h7.5M8.25 12.75h7.5',
    'Partidas ao vivo' => 'M12 6v6h4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    'Pendentes de finalização' => 'M4.5 12.75l6 6 9-13.5',
    'Gestores pendentes' => 'M15 19.5a3 3 0 00-6 0M15 8.25a3 3 0 11-6 0 3 3 0 016 0z',
    'Times cadastrados' => 'M3.75 6.75h16.5v10.5H3.75zM8.25 19.5h7.5',
    'Jogadores' => 'M15 19.5a3 3 0 00-6 0M15 8.25a3 3 0 11-6 0 3 3 0 016 0z',
    'Partidas pendentes' => 'M12 6v6h4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
  }.freeze

  def admin_kpi_icon(label)
    path = ADMIN_KPI_ICON_PATHS[label.to_s]
    return ''.html_safe if path.blank?

    admin_svg_icon(path, 'h-4 w-4 shrink-0 text-graphite')
  end
end
