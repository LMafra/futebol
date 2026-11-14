# Plain-text summaries of a championship for the Revisão step of the wizard (AdminChampionshipForm).
module ChampionshipSummary
  POSITIONS = { goalkeeper: %w[goleiro goleiros], defender: %w[defensor defensores],
                midfielder: %w[meio-campista meio-campistas], forward: %w[atacante atacantes] }.freeze

  def self.squad(limits)
    POSITIONS.map do |position, (singular, plural)|
      count = limits.fetch(position)
      "#{count} #{count == 1 ? singular : plural}"
    end.to_sentence(two_words_connector: ' e ', last_word_connector: ' e ')
  end

  def self.suggestion(championship)
    "Sugestão para #{Core::Championship::MODALITY[:kind][championship.kind]}: #{squad(championship.cartola_defaults)}."
  end

  def self.review_rows(championship)
    [
      ['dados', 'Dados', dados(championship)],
      ['modalidade', 'Modalidade', championship.modality_label],
      ['esquadrao', 'Esquadrão', esquadrao(championship)],
      ['premiacao', 'Premiação', premiacao(championship)]
    ]
  end

  def self.dados(championship)
    "#{championship.name} · #{championship.season} · #{championship.private? ? 'privado' : 'público'}"
  end

  def self.esquadrao(championship)
    limits = POSITIONS.keys.index_with { |position| championship.public_send(:"cartola_#{position}_limit") }
    "#{squad(limits)} · #{format('orçamento de C$ %.2f', championship.cartola_initial_budget)}"
  end

  def self.premiacao(championship)
    return 'Sem premiação' unless championship.prize?

    places = Core::Championship::PRIZE_PLACES.count { |place| championship.public_send(place).present? }
    places_text = places == 1 ? '1 colocação premiada' : "#{places} colocações premiadas"
    [championship.prize_description.presence, (places_text if places.positive?)].compact.join(' · ')
  end
end
