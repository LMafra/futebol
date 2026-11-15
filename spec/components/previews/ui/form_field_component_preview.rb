module Ui
  # @label Form Field
  class FormFieldComponentPreview < ViewComponent::Preview
    def default
      render FormFieldComponent.new(name: :name, label: 'Nome', value: 'Copa')
    end

    def loading
      render FormFieldComponent.new(state: :loading)
    end

    def empty
      render FormFieldComponent.new(state: :empty)
    end

    def error
      render FormFieldComponent.new(state: :error)
    end
  end
end
