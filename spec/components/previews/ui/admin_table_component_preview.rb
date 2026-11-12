module Ui
  # @label Admin table
  class AdminTableComponentPreview < ViewComponent::Preview
    HEADERS = [
      { label: 'Campeonato' },
      { label: 'Times', numeric: true },
      { label: 'Partidas', numeric: true }
    ].freeze

    ROWS = [
      ['Brasileirão Demo', 20, 38],
      ['Copa do Bairro', 8, 12]
    ].freeze

    def default
      render AdminTableComponent.new(headers: HEADERS, rows: ROWS, texts: { label: 'Campeonatos' })
    end

    def loading
      render AdminTableComponent.new(state: :loading)
    end

    def empty
      render AdminTableComponent.new(state: :empty, texts: { empty: 'Sem campeonatos.' })
    end

    def error
      render AdminTableComponent.new(state: :error)
    end
  end
end
