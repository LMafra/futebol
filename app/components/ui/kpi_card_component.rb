module Ui
  # Actionable dashboard KPI: number + label + CTA; whole card filters the Action Center.
  class KpiCardComponent < BaseComponent
    STATUSES = %i[normal zero alert].freeze
    OPTIONS = %i[value label action_text action_path status data_role data_label].freeze

    attr_reader :value, :label, :action_text, :action_path, :status, :data_role, :data_label

    def initialize(state: :default, **options)
      super(state:)
      assign_kpi_options(options)
      require_in_default_state!(:label, @label)
      require_in_default_state!(:value, @value)
      @status = default? ? resolve_status(options[:status]) : :normal
    end

    def zero_status? = status == :zero
    def alert_status? = status == :alert

    def display_value = zero_status? ? '0' : value

    def card_classes
      accent = case status
               when :alert then 'border-l-cartola'
               when :zero then 'border-l-pitch'
               else 'border-l-ink'
               end
      'block rounded-md border border-rule border-l-[3px] bg-white px-4 py-3 text-ink ' \
        "no-underline hover:bg-paper focus:outline-hidden focus-visible:ring-2 focus-visible:ring-ink #{accent}"
    end

    private

    def assign_kpi_options(options)
      unknown = options.keys - OPTIONS
      raise ArgumentError, "unknown kpi options: #{unknown.join(', ')}" if unknown.any?

      @value = options[:value]
      @label = options[:label]
      @action_text = options[:action_text]
      @action_path = options[:action_path]
      @data_role = options.fetch(:data_role, 'kpi-card')
      @data_label = options[:data_label] || @label
    end

    def resolve_status(value)
      key = (value || inferred_status).to_s.to_sym
      return key if STATUSES.include?(key)

      raise ArgumentError, "invalid kpi status #{value.inspect} (expected one of: #{STATUSES.join(', ')})"
    end

    def inferred_status
      value.to_i.zero? ? :zero : :normal
    end
  end
end
