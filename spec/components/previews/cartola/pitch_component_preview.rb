module Cartola
  # @label Cartola pitch
  class PitchComponentPreview < ViewComponent::Preview
    def default
      render PitchComponent.new(lineup: sample_lineup)
    end

    def loading
      render PitchComponent.new(state: :loading)
    end

    def empty
      render PitchComponent.new(state: :empty)
    end

    def error
      render PitchComponent.new(state: :error)
    end

    private

    def sample_lineup
      team = Core::Team.new(name: 'Flamengo', short_name: 'FLA')
      players = { 'GOL' => 1, 'LAT' => 2, 'ZAG' => 2, 'MEI' => 3, 'ATA' => 3 }.flat_map do |position, count|
        Array.new(count) do |index|
          Core::Player.new(name: "#{position.capitalize} #{index + 1}", position:, team:, cost: 8.5)
        end
      end
      Cartola::Lineup.new(formation: '4-3-3').tap { |lineup| players.each { |player| lineup.lineup_players.build(player:) } }
    end
  end
end
