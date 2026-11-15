module Ui
  # Labeled form control with the seven DS states (default/hover/focus/disabled/error/loading/empty).
  class FormFieldComponent < BaseComponent
    FIELD_STATES = (%i[hover focus disabled] + STATES).freeze
    OPTIONS = %i[name label value hint error field_state].freeze

    attr_reader :name, :label, :value, :hint, :error, :field_state

    def initialize(state: :default, **options)
      super(state:)
      assign_form_field_options(options)
      apply_default_field_state!
      require_in_default_state!(:name, @name) if default?
      require_in_default_state!(:label, @label) if default?
    end

    def error_state? = field_state == :error || error.present?

    def input_classes
      base = 'min-h-12 w-full rounded-sm bg-white px-3 py-2 font-body text-ink ' \
             'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-pitch'
      border = error_state? ? 'border-2 border-red-800' : 'border border-rule'
      disabled = field_state == :disabled ? 'cursor-not-allowed opacity-50' : ''
      [base, border, disabled].join(' ')
    end

    private

    def assign_form_field_options(options)
      unknown = options.keys - OPTIONS
      raise ArgumentError, "unknown form field options: #{unknown.join(', ')}" if unknown.any?

      @name = options[:name]
      @label = options[:label]
      @value = options[:value]
      @hint = options[:hint]
      @error = options[:error]
      @field_state = (options.fetch(:field_state, :default) || :default).to_s.to_sym
    end

    def apply_default_field_state!
      return unless default? && @error.present? && @field_state == :default

      @field_state = :error
    end
  end
end
