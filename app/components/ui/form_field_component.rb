module Ui
  # Labeled form control with the seven DS states (default/hover/focus/disabled/error/loading/empty).
  class FormFieldComponent < BaseComponent
    FIELD_STATES = (%i[hover focus disabled] + STATES).freeze

    attr_reader :name, :label, :value, :hint, :error, :field_state

    def initialize(name: nil, label: nil, value: nil, hint: nil, error: nil, field_state: :default, state: :default)
      super(state:)
      @name = name
      @label = label
      @value = value
      @hint = hint
      @error = error
      @field_state = (field_state || :default).to_s.to_sym
      @field_state = :error if default? && @error.present? && @field_state == :default
      require_in_default_state!(:name, name) if default?
      require_in_default_state!(:label, label) if default?
    end

    def error_state? = field_state == :error || error.present?

    def input_classes
      base = 'min-h-12 w-full rounded-sm bg-white px-3 py-2 font-body text-ink ' \
             'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-pitch'
      border = error_state? ? 'border-2 border-red-800' : 'border border-rule'
      disabled = field_state == :disabled ? 'cursor-not-allowed opacity-50' : ''
      [base, border, disabled].join(' ')
    end
  end
end
