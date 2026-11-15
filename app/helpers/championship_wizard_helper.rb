# Creation wizard of a championship (ADR 0006): named steps, each validated and saved by the server before the
# next one opens. The first step creates the draft; the last one (Revisão) publishes it.
module ChampionshipWizardHelper
  Step = Data.define(:key, :label, :why)

  CHAMPIONSHIP_STEPS = [
    Step.new('dados', 'Dados', 'Comece pelo nome e pela temporada: é assim que o campeonato aparece para todos.'),
    Step.new('modalidade', 'Modalidade',
             'Com o rascunho salvo, diga como se joga: o tipo sugere os limites do Esquadrão da próxima etapa.'),
    Step.new('esquadrao', 'Esquadrão',
             'Os limites vêm da modalidade escolhida; ajuste só se o seu campeonato for diferente.'),
    Step.new('premiacao', 'Premiação',
             'Com as regras definidas, conte o que os primeiros colocados ganham. É opcional.'),
    Step.new('revisao', 'Revisão',
             'Confira tudo antes de publicar: só depois disso o campeonato aparece no site.')
  ].freeze
  STEP_KEYS = CHAMPIONSHIP_STEPS.map(&:key).freeze

  # The step to render: always the first on a new record, the requested one on a draft, none once published.
  def championship_wizard_step(championship)
    return CHAMPIONSHIP_STEPS.first if championship.new_record?
    return unless championship.draft?

    CHAMPIONSHIP_STEPS.find { |step| step.key == params[:step] } || CHAMPIONSHIP_STEPS.first
  end

  def championship_wizard_nav(championship, current, namespace)
    tag.nav(aria: { label: 'Etapas do cadastro' }, class: 'mb-6', data: { role: 'wizard-nav' }) do
      safe_join([
                  tag.ol(class: 'flex flex-wrap gap-2 font-body text-sm') do
                    safe_join(CHAMPIONSHIP_STEPS.each_with_index.map do |step, index|
                      tag.li { wizard_step_item(championship, step, index, current, namespace) }
                    end)
                  end,
                  tag.p(current.why, class: 'mt-3 text-sm font-body text-graphite', data: { role: 'wizard-why' })
                ])
    end
  end

  def championship_wizard_controls(championship, current, namespace)
    label = current == CHAMPIONSHIP_STEPS.last ? 'Publicar campeonato' : 'Salvar e continuar'
    tag.div(class: 'mb-6 flex flex-wrap items-center gap-3', data: { role: 'wizard-controls' }) do
      safe_join([
        hidden_field_tag(:step, current.key, id: nil),
        submit_tag(label, name: nil, class: AdminHelper::ADMIN_BUTTON_CLASSES),
        wizard_back_link(championship, current, namespace)
      ].compact)
    end
  end

  def wizard_step_path(championship, step_key, namespace)
    public_send(:"edit_#{namespace}_championship_path", championship, step: step_key)
  end

  private

  def wizard_back_link(championship, current, namespace)
    index = CHAMPIONSHIP_STEPS.index(current)
    return if index.zero? || championship.new_record?

    previous = CHAMPIONSHIP_STEPS[index - 1]
    link_to("Voltar para #{previous.label}", wizard_step_path(championship, previous.key, namespace),
            class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES)
  end

  def wizard_step_item(championship, step, index, current, namespace)
    label = "#{index + 1}. #{step.label}"
    return tag.span(label, class: wizard_step_classes, aria: { current: 'step' }) if step == current
    return tag.span(label, class: "#{wizard_step_classes} text-graphite") if championship.new_record?

    link_to(label, wizard_step_path(championship, step.key, namespace), class: wizard_step_classes)
  end

  def wizard_step_classes
    'inline-flex min-h-10 items-center rounded-md border border-graphite/70 bg-white px-3 font-semibold text-ink ' \
      'no-underline aria-[current=step]:border-cartola aria-[current=step]:bg-cartola'
  end
end
