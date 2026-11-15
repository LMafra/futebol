module Ui
  # @label Kpi Card
  class KpiCardComponentPreview < ViewComponent::Preview
    def default
      render KpiCardComponent.new(value: 3, label: 'Partidas pendentes', action_text: 'Ver fila',
                                  action_path: '/admin?urgency=high')
    end

    def loading
      render KpiCardComponent.new(value: 0, label: '…', state: :loading)
    end

    def empty
      render KpiCardComponent.new(value: 0, label: '…', state: :empty)
    end

    def error
      render KpiCardComponent.new(value: 0, label: '…', state: :error)
    end
  end
end
