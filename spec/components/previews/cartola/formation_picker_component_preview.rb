module Cartola
  # @label Cartola formation picker
  class FormationPickerComponentPreview < ViewComponent::Preview
    def default
      render FormationPickerComponent.new(selected: '4-3-3')
    end

    def loading
      render FormationPickerComponent.new(state: :loading)
    end

    def empty
      render FormationPickerComponent.new(state: :empty)
    end

    def error
      render FormationPickerComponent.new(selected: '4-3-3', error_message: 'Formação não está na lista.',
                                          state: :error)
    end
  end
end
