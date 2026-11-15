module Ui
  # @label Bottom Nav
  class BottomNavComponentPreview < ViewComponent::Preview
    def default
      render BottomNavComponent.new(
        items: [
          { label: 'Início', path: '/gestor', current: true },
          { label: 'Partidas', path: '/gestor/matches' },
          { label: 'Times', path: '/gestor/teams' },
          { label: 'Campeonatos', path: '/gestor/championships' }
        ]
      )
    end

    def loading
      render BottomNavComponent.new(state: :loading)
    end

    def empty
      render BottomNavComponent.new(state: :empty)
    end

    def error
      render BottomNavComponent.new(state: :error)
    end
  end
end
