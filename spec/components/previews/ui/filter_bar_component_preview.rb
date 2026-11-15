module Ui
  # @label Filter Bar
  class FilterBarComponentPreview < ViewComponent::Preview
    def default
      render FilterBarComponent.new(
        chips: [{ label: 'Situação: Ao vivo', remove_path: '#' }],
        clear_path: '#',
        views: [
          { key: 'pending', label: 'Minhas Pendências', path: '#', current: true },
          { key: 'all', label: 'Todas as Partidas', path: '#' }
        ]
      ) do |bar|
        bar.with_controls { 'Busca e selects' }
      end
    end

    def loading
      render FilterBarComponent.new(state: :loading)
    end

    def empty
      render FilterBarComponent.new(state: :empty)
    end

    def error
      render FilterBarComponent.new(state: :error)
    end
  end
end
