module Ui
  # @label Action Center
  class ActionCenterComponentPreview < ViewComponent::Preview
    def default
      render ActionCenterComponent.new(
        groups: {
          critical: [{ title: 'Ao vivo', context: 'Precisa finalizar', action_text: 'Finalizar', action_path: '#' }],
          high: [],
          medium: []
        }
      )
    end

    def loading
      render ActionCenterComponent.new(state: :loading)
    end

    def empty
      render ActionCenterComponent.new(state: :empty)
    end

    def error
      render ActionCenterComponent.new(state: :error)
    end
  end
end
