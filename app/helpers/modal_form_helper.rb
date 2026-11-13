# Creation forms in a <dialog> (modal_controller.js) on the Admin/Gestor pages. Any link with
# data-modal-open="modal-<id>" opens the dialog; without JavaScript the link goes to the full "new" page, or to
# ?modal=<id>, which renders the dialog already open, inline. The form posts `modal` and `return_to`; on validation
# errors ModalFormRedirects sends the user back with ?modal=<id>, and the flash carries the errors and the typed
# values to reopen the dialog filled in.
module ModalFormHelper
  DIALOG_CLASSES = 'm-auto max-h-[90dvh] w-[calc(100%-2rem)] max-w-lg overflow-y-auto rounded-md border ' \
                   'border-rule bg-white p-0 text-ink shadow-xl backdrop:bg-ink/60'.freeze
  INVALID_INPUT_CLASSES = 'border-2 border-ink bg-loss'.freeze
  ERROR_TEXT_CLASSES = 'mt-1 text-sm font-body font-semibold text-ink'.freeze

  def modal_trigger(label, modal, fallback_url, classes: AdminHelper::ADMIN_BUTTON_CLASSES)
    link_to label, fallback_url, class: classes, data: { modal_open: "modal-#{modal}" }, aria: { haspopup: 'dialog' }
  end

  # The block receives the form builder and renders the fields, usually with modal_field. The params use the
  # dialog id as their key (team, player, match, pool), as the ActiveAdmin forms do.
  def modal_form(modal, title:, url:, submit:, record: nil, &)
    dom_id = "modal-#{modal}"
    tag.dialog(id: dom_id, class: DIALOG_CLASSES, open: params[:modal] == modal.to_s,
               aria: { labelledby: "#{dom_id}-title" },
               data: { controller: 'modal', action: 'click->modal#backdrop close->modal#closed' }) do
      tag.div(class: 'flex flex-col gap-4 p-4') do
        safe_join([tag.h2(title, id: "#{dom_id}-title", class: 'font-display text-xl font-semibold text-ink'),
                   modal_form_body(modal, modal_record(modal, record), url:, submit:, &)])
      end
    end
  end

  # Options: `as:` (form builder method, text_field by default) or `choices:` (+ `include_blank:`) for a select;
  # the rest goes to the input.
  def modal_field(form, attribute, label: nil, hint: nil, **options)
    input_id = form.field_id(attribute)
    errors = form.object ? form.object.errors[attribute] : []
    label ||= form.object.class.human_attribute_name(attribute)
    tag.div do
      safe_join([form.label(attribute, label, class: AdminHelper::ADMIN_LABEL_CLASSES),
                 modal_input(form, attribute, options.merge(modal_input_html(input_id, hint, errors))),
                 *modal_notes(input_id, hint, errors)])
    end
  end

  # A typed value for fields without a record behind them, such as the team of an enrollment.
  def modal_value(modal, key) = modal_state(modal)&.dig('values', key.to_s)

  private

  def modal_form_body(modal, record, url:, submit:, &fields)
    multipart = record.class.respond_to?(:attachment_reflections) && record.class.attachment_reflections.any?
    form_with(model: record || false, scope: record && modal, url:, multipart:, class: 'flex flex-col gap-4') do |form|
      return_to = hidden_field_tag(:return_to, modal_return_to(modal), id: nil)
      safe_join([hidden_field_tag(:modal, modal, id: nil), return_to,
                 modal_error_summary(modal), capture(form, &fields), modal_actions(submit)])
    end
  end

  # The page state (?membro=, ?view=) survives the round trip; the dialog's own params do not.
  def modal_return_to(modal)
    query = request.query_parameters.except('modal', modal.to_s)
    query.empty? ? request.path : "#{request.path}?#{query.to_query}"
  end

  def modal_input(form, attribute, options)
    as = options.delete(:as) || :text_field
    choices = options.delete(:choices)
    return form.public_send(as, attribute, options) unless choices

    form.select(attribute, choices, { include_blank: options.delete(:include_blank) }, options)
  end

  def modal_notes(input_id, hint, errors)
    [(tag.p(hint, id: "#{input_id}_hint", class: AdminHelper::ADMIN_MUTED_TEXT_CLASSES) if hint),
     (tag.p(errors.to_sentence, id: "#{input_id}_error", class: ERROR_TEXT_CLASSES) if errors.any?)].compact
  end

  def modal_state(modal)
    state = flash[:modal]
    state if state.is_a?(Hash) && state['id'] == modal.to_s
  end

  def modal_record(modal, record)
    state = modal_state(modal)
    return record unless record && state

    record.assign_attributes(state['values'].to_h.slice(*record.attribute_names))
    state['errors'].to_h.each { |attribute, messages| messages.each { record.errors.add(attribute, _1) } }
    record
  end

  def modal_error_summary(modal)
    messages = modal_state(modal)&.dig('messages')
    return if messages.blank?

    tag.div(role: 'alert', class: AdminHelper::ADMIN_ALERT_CLASSES) do
      safe_join([tag.p('Corrija para continuar:', class: 'font-semibold'),
                 tag.ul(safe_join(messages.map { tag.li(_1) }), class: 'list-disc ps-4')])
    end
  end

  def modal_actions(submit)
    tag.div(class: 'flex flex-wrap justify-end gap-2') do
      safe_join([button_tag('Cancelar', type: :button, class: AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES,
                                        data: { action: 'modal#close' }),
                 button_tag(submit, type: :submit, class: AdminHelper::ADMIN_BUTTON_CLASSES)])
    end
  end

  def modal_input_html(input_id, hint, errors)
    describedby = [("#{input_id}_hint" if hint), ("#{input_id}_error" if errors.any?)].compact.join(' ').presence
    classes = [AdminHelper::ADMIN_INPUT_CLASSES, (INVALID_INPUT_CLASSES if errors.any?)].compact.join(' ')
    { class: classes, aria: { describedby:, invalid: (true if errors.any?) } }
  end
end
