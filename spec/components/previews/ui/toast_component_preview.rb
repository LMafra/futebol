module Ui
  # @label Toast
  class ToastComponentPreview < ViewComponent::Preview
    def default
      render ToastComponent.new(message: 'Campeonato atualizado', variant: :success)
    end

    def loading
      render ToastComponent.new(state: :loading)
    end

    def empty
      render ToastComponent.new(state: :empty)
    end

    def error
      render ToastComponent.new(state: :error)
    end
  end
end
