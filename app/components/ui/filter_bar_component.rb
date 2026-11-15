module Ui
  # Horizontal filter bar: controls + removable chips + clear-all + saved views.
  class FilterBarComponent < BaseComponent
    Chip = Data.define(:label, :remove_path)
    ViewTab = Data.define(:key, :label, :path, :current)

    renders_one :controls

    attr_reader :chips, :clear_path, :views, :layout_toggle

    def initialize(chips: [], clear_path: nil, views: [], layout_toggle: nil, state: :default)
      super(state:)
      @chips = Array(chips).map { |chip| coerce_chip(chip) }
      @clear_path = clear_path
      @views = Array(views).map { |view| coerce_view(view) }
      @layout_toggle = layout_toggle
    end

    def chips? = chips.any?

    private

    def coerce_chip(chip)
      return chip if chip.is_a?(Chip)

      Chip.new(label: chip.fetch(:label), remove_path: chip.fetch(:remove_path))
    end

    def coerce_view(view)
      return view if view.is_a?(ViewTab)

      ViewTab.new(
        key: view.fetch(:key),
        label: view.fetch(:label),
        path: view.fetch(:path),
        current: view.fetch(:current, false)
      )
    end
  end
end
