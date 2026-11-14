module Ui
  # Empty admin/gestor surface with SVG glyph, title, description and optional CTA.
  class EmptyStateComponent < BaseComponent
    renders_one :action

    attr_reader :title, :description

    def initialize(title: nil, description: nil, state: :default)
      super(state:)
      @title = title
      @description = description
      require_in_default_state!(:title, title)
    end
  end
end
