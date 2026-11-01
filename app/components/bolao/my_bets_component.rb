module Bolao
  class MyBetsComponent < Ui::BaseComponent
    RESULTS = {
      exact: { label: 'Exato', glyph: '✓', tint: 'bg-win' },
      winner: { label: 'Vencedor', glyph: '≈', tint: 'bg-draw' },
      miss: { label: 'Errou', glyph: '✗', tint: 'bg-loss' },
      pending: { label: 'Aguardando', glyph: '·', tint: 'bg-paper' }
    }.freeze

    attr_reader :results

    # results: Bolao::BetResults::Result list.
    def initialize(results: nil, state: :default)
      super(state:)
      @results = results
      require_in_default_state!(:results, results)
    end

    private

    def badge(result) = RESULTS.fetch(result.result)

    def guess(result) = "#{result.prediction.home_guess} × #{result.prediction.away_guess}"

    def final_score(match) = match.home_score.nil? ? '–' : "#{match.home_score} × #{match.away_score}"

    def points(result) = result.pending? ? '–' : result.points
  end
end
