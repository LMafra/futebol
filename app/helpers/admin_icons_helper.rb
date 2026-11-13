module AdminIconsHelper
  # Compact Heroicons-style paths for task sidebar sections (no emoji).
  ADMIN_NAV_ICON_PATHS = {
    'Visão geral' => 'M3 9.75L12 3l9 6.75V21a.75.75 0 01-.75.75H3.75A.75.75 0 013 21V9.75z',
    'Painel' => 'M3 9.75L12 3l9 6.75V21a.75.75 0 01-.75.75H3.75A.75.75 0 013 21V9.75z',
    'Dashboard' => 'M3 9.75L12 3l9 6.75V21a.75.75 0 01-.75.75H3.75A.75.75 0 013 21V9.75z',
    'Campeonatos' => 'M4.5 5.25h15v13.5h-15zM8.25 9h7.5M8.25 12.75h7.5',
    'Partidas' => 'M12 6v6h4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    'Times' => 'M12 3l7.5 3v6c0 4.5-3.3 7.9-7.5 9-4.2-1.1-7.5-4.5-7.5-9V6z',
    'Participantes' => 'M15 19.5a3 3 0 00-6 0M15 8.25a3 3 0 11-6 0 3 3 0 016 0zM19.5 19.5a2.25 2.25 0 00-2.25-2.25',
    'Configurações' => 'M12 15.75a3.75 3.75 0 100-7.5 3.75 3.75 0 000 7.5zM4.5 12h3M16.5 12h3M12 4.5v3M12 16.5v3'
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

  # The accessible label names the verb and the row ("Abrir Real Paraisópolis"): every row has the same icons.
  def admin_icon_action_link(verb, href, icon, subject: nil, **html_options)
    label = [verb, subject.presence].compact.join(' ')
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
    'Pontuação pendente' => 'M4.5 12.75l6 6 9-13.5',
    'Gestores pendentes' => 'M15 19.5a3 3 0 00-6 0M15 8.25a3 3 0 11-6 0 3 3 0 016 0z',
    'Partidas hoje' => 'M6.75 3v2.25M17.25 3v2.25M3.75 7.5h16.5v12H3.75z',
    'Aguardando scouts' => 'M16.5 6.75h-9v10.5h9zM9.75 9.75h4.5M9.75 12.75h4.5M9.75 15.75h3',
    'Aguardando finalização' => 'M4.5 12.75l6 6 9-13.5'
  }.freeze

  def admin_kpi_icon(label)
    path = ADMIN_KPI_ICON_PATHS[label.to_s]
    return ''.html_safe if path.blank?

    admin_svg_icon(path, 'h-4 w-4 shrink-0 text-graphite')
  end
end
