# Texts of the single match page (TICKET-0097) and of its notices.
module MatchBoardHelper
  STAT_BUTTON_LABELS = { goals: 'Gol', assists: 'Assist.', yellow_cards: 'Amarelo', red_cards: 'Vermelho',
                         own_goals: 'Gol contra', saves: 'Defesa', penalty_saves: 'Def. pênalti' }.freeze

  # "Gol · Zé do Gol · 32' · 1º tempo"; minute and period only when known.
  def lance_text(event)
    [scout_label(event.stat.to_sym), event.player.name, event.minute && "#{event.minute}'", event.period_label]
      .compact.join(' · ')
  end

  def lance_notice(event) = "Lance registrado: #{lance_text(event)}."

  def lance_button_label(stat) = STAT_BUTTON_LABELS.fetch(stat)

  # The trigger of the lance dialog for a player and stat; without JavaScript it opens the dialog through the URL.
  def lance_trigger(line, stat)
    values = { lance_player_id: line.player.id, lance_stat: stat, lance_minute: '',
               'modal-lance-title': "#{scout_label(stat)} · #{line.player.name}" }
    link_to "+ #{lance_button_label(stat)}",
            "?#{{ modal: 'lance', lance: { player_id: line.player.id, stat: } }.to_query}",
            class: "#{AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES} px-2 text-sm",
            data: { modal_open: 'modal-lance', modal_values: values.to_json },
            aria: { haspopup: 'dialog', label: "Lançar #{scout_label(stat).downcase} de #{line.player.name}" }
  end
end
