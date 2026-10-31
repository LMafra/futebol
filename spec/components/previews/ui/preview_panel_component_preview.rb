module Ui
  # @label Preview panel
  class PreviewPanelComponentPreview < ViewComponent::Preview
    def default
      render PreviewPanelComponent.new(preview: sample_preview)
    end

    def loading
      render PreviewPanelComponent.new(state: :loading)
    end

    def empty
      render PreviewPanelComponent.new(state: :empty)
    end

    def error
      render PreviewPanelComponent.new(state: :error, error_message: 'Partida ainda não encerrada.')
    end

    private

    def sample_preview
      PreviewPanelComponent::Preview.new(
        home_team: 'Flamengo', away_team: 'Palmeiras', home_score: 2, away_score: 1,
        entries: [
          PreviewPanelComponent::Entry.new(participant: 'Ana', points: 10),
          PreviewPanelComponent::Entry.new(participant: 'Bruno', points: 5),
          PreviewPanelComponent::Entry.new(participant: 'Carla', points: 0)
        ]
      )
    end
  end
end
