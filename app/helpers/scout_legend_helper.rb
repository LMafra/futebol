module ScoutLegendHelper
  # SG here is the scout "jogo sem sofrer gols"; in the standings table SG means "saldo de gols".
  SCOUT_ABBREVIATIONS = {
    goals: %w[G Gol], assists: %w[A Assistência], clean_sheet: ['SG', 'Jogo sem sofrer gols'],
    penalty_saves: ['DP', 'Defesa de pênalti'], saves: ['DE', 'Defesa (só goleiros)'],
    yellow_cards: ['CA', 'Cartão amarelo'], red_cards: ['CV', 'Cartão vermelho'], own_goals: ['GC', 'Gol contra']
  }.freeze

  def scout_abbreviation(scout) = SCOUT_ABBREVIATIONS.fetch(scout).first

  def scout_label(scout) = SCOUT_ABBREVIATIONS.fetch(scout).last

  # Table header: the abbreviation (with its meaning on hover) from 640px up, the full label on phones.
  def abbreviated_header(abbreviation, label)
    safe_join([tag.abbr(abbreviation, title: label, class: 'hidden no-underline sm:inline'),
               tag.span(label, class: 'sm:hidden')])
  end

  def scout_header(scout) = abbreviated_header(scout_abbreviation(scout), scout_label(scout))

  def scout_legend(scouts = SCOUT_ABBREVIATIONS.keys)
    items = scouts.map do |scout|
      tag.div(class: 'flex gap-1') do
        tag.dt(scout_abbreviation(scout), class: 'font-bold') + tag.dd(scout_label(scout))
      end
    end
    tag.dl(safe_join(items), class: 'mb-3 flex flex-wrap gap-x-4 gap-y-1 text-sm text-ink',
                             aria: { label: 'Legenda dos scouts' }, data: { role: 'scout-legend' })
  end
end
