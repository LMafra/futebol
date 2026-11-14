# The single next step of a match (Gestor::MatchQueue#step_for), in the Gestor queue and the Admin/Gestor match
# lists. Steps without a page of their own (or edit on /admin, where matches are not edited) are a note.
module MatchStepsHelper
  MATCH_STEP_LINKS = { edit: 'Editar partida', scouts: 'Registrar lances', finalize: 'Finalizar partida' }.freeze
  MATCH_STEP_NOTES = { edit: 'Agendada', scoring: 'Aguardando a pontuação', scored: 'Concluída',
                       reverted: 'Aguardando nova pontuação' }.freeze

  def match_next_step(match, step, namespace, classes: inline_link_classes(tone: :ink), role: 'match-step')
    path = match_step_path(match, step, namespace)
    return tag.span(MATCH_STEP_NOTES.fetch(step), class: AdminHelper::ADMIN_MUTED_TEXT_CLASSES) unless path

    link_to MATCH_STEP_LINKS.fetch(step), path, class: classes, data: { role: }
  end

  def match_step_path(match, step, namespace)
    case step
    when :edit then edit_gestor_match_path(match) if namespace == :gestor
    when :scouts then public_send(:"#{namespace}_match_path", match)
    when :finalize then public_send(:"#{namespace}_match_path", match, modal: 'finalize')
    end
  end
end
