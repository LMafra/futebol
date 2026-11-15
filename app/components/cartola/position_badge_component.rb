module Cartola
  # Compact position chip (GOL, ZAG, LAT, MEI, ATA) using design-system tones.
  class PositionBadgeComponent < Ui::BaseComponent
    TONES = {
      'GOL' => 'bg-pitch/15 text-pitch',
      'ZAG' => 'bg-ink/10 text-ink',
      'LAT' => 'bg-graphite/15 text-graphite',
      'MEI' => 'bg-cartola/15 text-cartola',
      'ATA' => 'bg-cartola/25 text-ink'
    }.freeze

    attr_reader :position

    def initialize(position:, state: :default)
      super(state:)
      @position = position.to_s.upcase
      require_in_default_state!(:position, position)
    end

    def tone_classes = TONES.fetch(position, 'bg-rule text-ink')
  end
end
