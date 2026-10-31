module Ui
  class PreviewPanelComponent < BaseComponent
    Entry = Data.define(:participant, :points)
    Preview = Data.define(:home_team, :away_team, :home_score, :away_score, :entries)

    attr_reader :preview, :error_message

    def initialize(preview: nil, state: :default, error_message: nil)
      super(state:)
      @preview = preview
      @error_message = error_message
      require_in_default_state!(:preview, preview)
    end

    private

    def total_points = preview.entries.sum(&:points)

    def signed(points) = points.positive? ? "+#{points}" : points.to_s
  end
end
