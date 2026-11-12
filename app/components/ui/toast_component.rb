module Ui
  # Flash/toast chip for admin feedback (success = pitch check, error = loss alert).
  class ToastComponent < BaseComponent
    VARIANTS = {
      success: { role: 'status', border: 'border-pitch/30', bg: 'bg-pitch/10', ink: 'text-pitch' },
      error: { role: 'alert', border: 'border-ink', bg: 'bg-loss', ink: 'text-ink' },
      notice: { role: 'status', border: 'border-pitch/30', bg: 'bg-pitch/10', ink: 'text-pitch' },
      alert: { role: 'alert', border: 'border-cartola', bg: 'bg-cartola/15', ink: 'text-ink' }
    }.freeze

    attr_reader :message, :variant

    def initialize(message: nil, variant: :success, state: :default)
      super(state:)
      @message = message
      @variant = normalize_variant(variant)
      require_in_default_state!(:message, message)
    end

    def style = VARIANTS.fetch(variant)

    private

    def normalize_variant(value)
      key = value.to_s.to_sym
      return key if VARIANTS.key?(key)

      raise ArgumentError, "invalid toast variant #{value.inspect}"
    end
  end
end
