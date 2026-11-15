# The single next step of a match (Gestor::MatchQueue#step_for), in the Gestor queue and the Admin/Gestor match
# lists. Steps without a page of their own (or edit on /admin, where matches are not edited) are a note.
module MatchStepsHelper
  MATCH_STEP_LINKS = { edit: 'Editar partida', scouts: 'Registrar lances', finalize: 'Finalizar partida' }.freeze
  MATCH_STEP_SHORT = { edit: 'Editar', scouts: 'Lances', finalize: 'Finalizar' }.freeze
  MATCH_STEP_NOTES = { edit: 'Agendada', scored: '—' }.freeze

  def match_next_step(match, step, namespace, classes: inline_link_classes(tone: :ink), role: 'match-step')
    path = match_step_path(match, step, namespace)
    return tag.span(MATCH_STEP_NOTES.fetch(step, '—'), class: AdminHelper::ADMIN_MUTED_TEXT_CLASSES) unless path

    link_to MATCH_STEP_LINKS.fetch(step), path, class: classes, data: { role: }
  end

  # Primary row action for the matches listing (live→Lances, pending→Finalizar, scheduled→Editar).
  def match_contextual_action(match, step, namespace)
    path = match_step_path(match, step, namespace)
    unless path
      return tag.span('—', class: AdminHelper::ADMIN_MUTED_TEXT_CLASSES, data: { role: 'match-primary-action' })
    end

    link_to MATCH_STEP_SHORT.fetch(step), path,
            class: "#{AdminHelper::ADMIN_BUTTON_CLASSES} min-h-11 min-w-[44px]",
            data: { role: 'match-primary-action' }
  end

  def match_step_path(match, step, namespace)
    case step
    when :edit then edit_gestor_match_path(match) if namespace == :gestor
    when :scouts then public_send(:"#{namespace}_match_path", match)
    when :finalize then public_send(:"#{namespace}_match_path", match, modal: 'finalize')
    end
  end
end
