module Ui
  # Dashboard work queue grouped by urgency (critical / high / medium).
  class ActionCenterComponent < BaseComponent
    URGENCIES = %i[critical high medium].freeze
    URGENCY_LABELS = {
      critical: 'Crítica',
      high: 'Alta',
      medium: 'Média'
    }.freeze

    Item = Data.define(:title, :context, :action_text, :action_path, :id)

    attr_reader :groups, :title, :filter_urgency

    def initialize(groups: {}, title: 'Central de ações', filter_urgency: nil, state: :default)
      super(state:)
      @title = title
      @filter_urgency = normalize_filter(filter_urgency)
      @groups = normalize_groups(groups)
    end

    def empty_groups? = groups.values.all?(&:empty?)

    def visible_groups
      return groups if filter_urgency.blank?

      groups.slice(filter_urgency)
    end

    def urgency_label(key) = URGENCY_LABELS.fetch(key)

    private

    def normalize_filter(value)
      return if value.blank?

      key = value.to_s.to_sym
      return key if URGENCIES.include?(key)

      nil
    end

    def normalize_groups(raw)
      URGENCIES.index_with do |urgency|
        Array(raw[urgency] || raw[urgency.to_s]).map { |item| coerce_item(item) }
      end
    end

    def coerce_item(item)
      return item if item.is_a?(Item)

      Item.new(
        title: item.fetch(:title),
        context: item[:context],
        action_text: item.fetch(:action_text),
        action_path: item.fetch(:action_path),
        id: item[:id]
      )
    end
  end
end
