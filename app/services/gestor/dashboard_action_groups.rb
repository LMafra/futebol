module Gestor
  # Builds Action Center groups from the match queue for /gestor.
  class DashboardActionGroups
    def self.call(items:, paths:, status_label:)
      new(items:, paths:, status_label:).call
    end

    def initialize(items:, paths:, status_label:)
      @items = items.reject { |item| item.step == :scored }
      @paths = paths
      @status_label = status_label
    end

    def call
      {
        critical: map_step(:scouts, 'Registrar lances'),
        high: map_step(:finalize, 'Finalizar partida'),
        medium: map_step(:edit, 'Editar partida')
      }
    end

    private

    def map_step(step, action_text)
      @items.select { |item| item.step == step }.first(5).map { |item| queue_item(item, action_text) }
    end

    def queue_item(item, action_text)
      match = item.match
      {
        id: "match-#{match.id}",
        title: match.to_s,
        context: "#{I18n.l(match.match_date, format: '%d/%m %H:%M')} · #{@status_label.call(match.status)}",
        action_text: action_text,
        action_path: path_for(item, match)
      }
    end

    def path_for(item, match)
      case item.step
      when :edit then @paths.edit_gestor_match_path(match)
      when :finalize then @paths.gestor_match_path(match, modal: 'finalize')
      else @paths.gestor_match_path(match)
      end
    end
  end
end
