module Ui
  # @label Form Error Summary
  class FormErrorSummaryComponentPreview < ViewComponent::Preview
    def default
      render FormErrorSummaryComponent.new(count: 2, messages: ['Nome é obrigatório', 'Rodada é inválida'])
    end

    def loading
      render FormErrorSummaryComponent.new(state: :loading)
    end

    def empty
      render FormErrorSummaryComponent.new(state: :empty)
    end

    def error
      render FormErrorSummaryComponent.new(state: :error)
    end
  end
end
