module ChampionshipWizardHelper
  CHAMPIONSHIP_STEPS = %w[Dados Esquadrão Bolão Premiação].freeze

  # Rendered hidden; form_wizard_controller.js reveals it, so without JavaScript the form stays one page.
  def championship_wizard_nav
    tag.nav(aria: { label: 'Etapas do cadastro' }, hidden: true, class: 'mb-6',
            data: { form_wizard_target: 'nav', role: 'wizard-nav' }) do
      safe_join([wizard_step_list, tag.p(class: 'mt-2 text-sm font-body text-graphite', aria: { live: 'polite' },
                                         data: { form_wizard_target: 'progress' })])
    end
  end

  def championship_wizard_controls
    tag.div(class: 'mb-6 flex flex-wrap gap-3', data: { role: 'wizard-controls' }) do
      safe_join([
                  tag.button('Voltar', type: 'button', hidden: true, class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES,
                                       data: { form_wizard_target: 'back', action: 'form-wizard#back' }),
                  tag.button('Continuar', type: 'button', hidden: true, class: AdminHelper::ADMIN_BUTTON_CLASSES,
                                          data: { form_wizard_target: 'next', action: 'form-wizard#next' })
                ])
    end
  end

  private

  def wizard_step_list
    tag.ol(class: 'flex flex-wrap gap-2 font-body text-sm') do
      safe_join(CHAMPIONSHIP_STEPS.each_with_index.map do |label, index|
        tag.li do
          tag.button("#{index + 1}. #{label}", type: 'button', class: wizard_step_classes,
                                               data: { form_wizard_target: 'stepLink', step: index,
                                                       action: 'form-wizard#jump' })
        end
      end)
    end
  end

  def wizard_step_classes
    'inline-flex min-h-10 cursor-pointer items-center rounded-md border border-graphite/70 bg-white px-3 ' \
      'font-semibold text-ink hover:bg-paper aria-[current=step]:border-cartola aria-[current=step]:bg-cartola ' \
      'focus:outline-hidden focus-visible:ring-2 focus-visible:ring-ink'
  end
end
