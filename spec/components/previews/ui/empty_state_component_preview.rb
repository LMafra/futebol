module Ui
  # @label Empty state
  class EmptyStateComponentPreview < ViewComponent::Preview
    def default
      render EmptyStateComponent.new(
        title: 'Nenhum campeonato',
        description: 'Crie o primeiro campeonato para começar.'
      ) do |empty|
        empty.with_action { tag.a('Criar campeonato', href: '#', class: 'font-semibold text-ink underline') }
      end
    end

    def loading
      render EmptyStateComponent.new(state: :loading)
    end

    def empty
      render EmptyStateComponent.new(state: :empty)
    end

    def error
      render EmptyStateComponent.new(state: :error)
    end
  end
end
