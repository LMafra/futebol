module Cartola
  # @label Cartola player picker
  class PlayerPickerComponentPreview < ViewComponent::Preview
    def default
      render PlayerPickerComponent.new(players: sample_players, selected_ids: [1, 3])
    end

    def loading
      render PlayerPickerComponent.new(state: :loading)
    end

    def empty
      render PlayerPickerComponent.new(players: [], state: :empty)
    end

    def error
      render PlayerPickerComponent.new(players: sample_players, selected_ids: [1], state: :error)
    end

    private

    def sample_players
      team = Core::Team.new(name: 'Palmeiras', short_name: 'PAL')
      %w[GOL LAT ZAG MEI ATA].each_with_index.map do |position, index|
        Core::Player.new(id: index + 1, name: "Jogador #{index + 1}", position:, team:, cost: 5 + index)
      end
    end
  end
end
