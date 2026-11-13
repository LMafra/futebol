# Championship form shared by /admin and /gestor (ADR 0006). A draft is filled one step at a time
# (ChampionshipWizardHelper, ChampionshipWizardActions); a published championship is edited on a single page.
module AdminChampionshipForm
  MODALITY_LABELS = { kind: 'Tipo', gender: 'Gênero', category: 'Categoria', level: 'Nível' }.freeze
  KIND_HINT = 'No rascunho, o tipo define os limites sugeridos do Esquadrão.'.freeze
  EDIT_SECTIONS = %w[dados modalidade esquadrao bolao premiacao].freeze

  DADOS = proc do |f, namespace, _wizard|
    f.inputs 'Dados' do
      f.input :name
      f.input :season
      f.input :external_id if namespace == :admin
      AdminImageInput.render(f, :logo, label: 'Logo')
      f.input :private, label: 'Campeonato privado?',
                        hint: 'Campeonatos privados não aparecem na home, na página pública nem no Simulador.'
    end
  end

  MODALIDADE = proc do |f, _namespace, _wizard|
    f.inputs 'Modalidade' do
      AdminChampionshipForm::MODALITY_LABELS.each do |field, label|
        f.input field, as: :select, label:, include_blank: false,
                       collection: Core::Championship::MODALITY.fetch(field).invert,
                       hint: (AdminChampionshipForm::KIND_HINT if field == :kind)
      end
    end
  end

  SQUAD_INPUTS = proc do |f|
    f.input :cartola_goalkeeper_limit, label: 'Limite de goleiros', input_html: { min: 0 }
    f.input :cartola_defender_limit, label: 'Limite de defensores', input_html: { min: 0 }
    f.input :cartola_midfielder_limit, label: 'Limite de meio-campistas', input_html: { min: 0 }
    f.input :cartola_forward_limit, label: 'Limite de atacantes', input_html: { min: 0 }
    f.input :cartola_initial_budget, label: 'Orçamento inicial (C$)', input_html: { min: 0, step: '0.01' }
    f.input :cartola_base_player_value, label: 'Valor base do jogador (C$)',
                                        hint: 'Usado para jogadores sem valor base próprio.',
                                        input_html: { min: 0, step: '0.01' }
  end

  ESQUADRAO = proc do |f, _namespace, wizard|
    suggestion = ChampionshipSummary.suggestion(f.object)
    if wizard
      para suggestion, class: 'mb-3 font-body text-sm text-ink', 'data-role': 'squad-suggestion'
      details(**(f.object.errors.any? ? { open: 'open' } : {})) do
        summary 'Opções avançadas: limites por posição e orçamento',
                class: 'min-h-10 cursor-pointer py-2 font-body text-sm font-semibold text-ink'
        f.inputs('Esquadrão') { instance_exec(f, &AdminChampionshipForm::SQUAD_INPUTS) }
      end
    else
      f.inputs 'Esquadrão' do
        li(class: 'input optional') { para suggestion, class: 'inline-hints' }
        instance_exec(f, &AdminChampionshipForm::SQUAD_INPUTS)
      end
    end
  end

  BOLAO = proc do |_f, namespace, _wizard|
    rules_path = public_send(:"#{namespace}_bolao_scoring_rules_path")
    panel 'Bolão' do
      para class: 'font-body text-sm text-ink' do
        text_node safe_join(['Os bolões deste campeonato são criados na página dele, depois de salvo. ' \
                             'As regras de pontuação valem para todos e ficam em ',
                             link_to('Regras do Bolão', rules_path, class: inline_link_classes(tone: :ink)), '.'])
      end
    end
  end

  PREMIACAO = proc do |f, _namespace, _wizard|
    f.inputs 'Premiação' do
      f.input :prize_description, label: 'Descrição geral', input_html: { rows: 3 }
      Core::Championship::PRIZE_PLACES.each { |place| f.input place }
    end
  end

  REVISAO = proc do |f, namespace, wizard|
    panel 'Revisão' do
      dl class: 'grid gap-3 font-body text-sm', 'data-role': 'wizard-review' do
        ChampionshipSummary.review_rows(f.object).each do |key, label, value|
          div class: 'flex flex-wrap items-baseline gap-x-3 border-b border-rule pb-2' do
            dt label, class: 'w-28 font-semibold text-ink'
            dd value, class: 'flex-1 text-ink'
            dd do
              a "Editar #{label.downcase}", href: wizard_step_path(f.object, key, namespace),
                                            class: inline_link_classes(tone: :ink)
            end
          end
        end
      end
    end
    instance_exec(f, namespace, wizard, &AdminChampionshipForm::BOLAO)
  end

  SECTIONS = { 'dados' => DADOS, 'modalidade' => MODALIDADE, 'esquadrao' => ESQUADRAO, 'bolao' => BOLAO,
               'premiacao' => PREMIACAO, 'revisao' => REVISAO }.freeze

  FORM = proc do |f, namespace|
    f.semantic_errors
    step = championship_wizard_step(f.object)
    if step
      text_node championship_wizard_nav(f.object, step, namespace)
      instance_exec(f, namespace, true, &AdminChampionshipForm::SECTIONS.fetch(step.key))
      text_node championship_wizard_controls(f.object, step, namespace)
    else
      AdminChampionshipForm::EDIT_SECTIONS.each do |key|
        instance_exec(f, namespace, false, &AdminChampionshipForm::SECTIONS.fetch(key))
      end
      f.actions
    end
  end

  def self.render(context, form, namespace:)
    context.instance_exec(form, namespace, &FORM)
  end
end
