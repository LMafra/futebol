module Ui
  # Editorial form section for ActiveAdmin / custom admin forms (Placar de Domingo).
  class FormSectionComponent < BaseComponent
    renders_one :body

    attr_reader :title

    def initialize(title: nil, state: :default)
      super(state:)
      @title = title
      require_in_default_state!(:title, title)
    end
  end
end
