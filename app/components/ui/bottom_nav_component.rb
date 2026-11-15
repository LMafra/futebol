module Ui
  # Mobile bottom navigation (3–4 items + Mais drawer). Hidden from sm and up.
  class BottomNavComponent < BaseComponent
    Item = Data.define(:label, :path, :icon_html, :current)

    attr_reader :items, :more_label

    def initialize(items: [], more_label: 'Mais', state: :default)
      super(state:)
      @items = Array(items).first(4).map { |item| coerce(item) }
      @more_label = more_label
    end

    def item_classes(active)
      base = 'flex min-h-14 w-full flex-col items-center justify-center gap-0.5 border-t-2 px-0 ' \
             'text-xs font-body font-semibold tracking-tight no-underline'
      tone = active ? 'border-pitch text-pitch' : 'border-transparent text-graphite'
      "#{base} #{tone}"
    end

    private

    def coerce(item)
      return item if item.is_a?(Item)

      Item.new(
        label: item.fetch(:label),
        path: item.fetch(:path),
        icon_html: item[:icon_html],
        current: item.fetch(:current, false)
      )
    end
  end
end
