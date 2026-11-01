module Bolao
  class MatchListComponent < Ui::BaseComponent
    CLOSED_LABEL = 'Palpites encerrados'.freeze

    attr_reader :pool, :matches, :bets_by_match

    def initialize(pool: nil, matches: nil, bets_by_match: {}, state: :default)
      super(state:)
      @pool = pool
      @matches = matches
      @bets_by_match = bets_by_match
      require_in_default_state!(:pool, pool)
      require_in_default_state!(:matches, matches)
    end

    private

    def bet_for(match) = bets_by_match[match.id] || Bolao::Prediction.new(pool:, match:)

    def form_state(match, bet)
      return :empty unless match.status == 'scheduled'

      bet.errors.any? ? :error : :default
    end

    def kickoff(match) = match.match_date.strftime('%d/%m · %H:%M')

    # Same format as app/javascript/controllers/countdown_controller.js.
    def countdown_label(match)
      seconds = (match.match_date - Time.current).to_i
      return CLOSED_LABEL unless seconds.positive?

      days, rest = seconds.divmod(86_400)
      format('%<days>dd %<clock>s', days:, clock: Time.at(rest).utc.strftime('%H:%M:%S'))
    end
  end
end
