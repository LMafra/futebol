# "Sobre esta tela": a short explanation under the title of each Admin/Gestor screen, from
# config/locales/page_intros.pt-BR.yml. It opens until the user closes it; dismissible_controller.js remembers that
# per screen. Lookup: page_intro.<namespace>.<controller>.<action>, then .default, then the same under `shared`.
module PageIntroHelper
  INTRO_ACTIONS = { 'create' => 'new', 'update' => 'edit' }.freeze

  def page_intro
    text = page_intro_text
    return if text.blank?

    tag.details(open: true, class: 'max-w-prose rounded-md border border-rule bg-white text-sm font-body text-ink',
                data: { controller: 'dismissible', dismissible_key_value: page_intro_key,
                        action: 'toggle->dismissible#remember', role: 'page-intro' }) do
      safe_join([tag.summary('Sobre esta tela', class: 'min-h-10 cursor-pointer px-3 py-2 font-semibold'),
                 tag.p(text, class: 'px-3 pb-3 text-graphite')])
    end
  end

  private

  def page_intro_key = "#{controller_path}##{INTRO_ACTIONS.fetch(action_name, action_name)}"

  def page_intro_text
    namespace, controller = controller_path.split('/', 2)
    action = INTRO_ACTIONS.fetch(action_name, action_name)
    keys = [namespace, 'shared'].flat_map do |scope|
      [:"page_intro.#{scope}.#{controller}.#{action}", :"page_intro.#{scope}.#{controller}.default"]
    end
    t(keys.first, default: [*keys.drop(1), ''])
  end
end
