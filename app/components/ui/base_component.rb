module Ui
  class BaseComponent < ViewComponent::Base
    include FormControlHelper

    STATES = %i[default loading empty error].freeze

    attr_reader :state

    def initialize(state: :default)
      super()
      @state = state.to_s.to_sym
      return if STATES.include?(@state)

      raise ArgumentError,
            "invalid state #{state.inspect} for #{self.class.name} (expected one of: #{STATES.join(', ')})"
    end

    STATES.each { |name| define_method(:"#{name}?") { state == name } }

    private

    def require_in_default_state!(name, value)
      raise ArgumentError, "#{name} is required in the default state" if default? && value.nil?
    end

    def rendered_state = state

    def root_attributes(label:)
      { data: { ui_state: rendered_state }, aria: { busy: loading?, label: } }
    end

    def skeleton_classes
      'animate-pulse rounded-sm bg-rule motion-reduce:animate-none'
    end

    def empty_notice(message)
      tag.p(message, class: 'rounded-md border border-dashed border-rule px-4 py-8 text-center text-graphite')
    end

    def error_classes
      'flex flex-wrap items-center gap-3 rounded-md border-l-4 border-ink bg-loss px-4 py-3 text-ink'
    end
  end
end
