module Cartola
  class FormationPickerComponent < Ui::BaseComponent
    attr_reader :selected, :error_message

    def initialize(selected: nil, error_message: nil, state: :default)
      super(state:)
      @selected = selected
      @error_message = error_message
      require_in_default_state!(:selected, selected)
    end

    private

    def formations = Cartola::Lineup::FORMATIONS

    def options? = default? || (error? && selected.present?)
  end
end
