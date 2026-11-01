module Ui
  class PredictionFormComponent < BaseComponent
    attr_reader :match, :prediction

    def initialize(match: nil, prediction: nil, state: :default)
      super(state:)
      @match = match
      @prediction = prediction
      require_in_default_state!(:match, match)
      require_in_default_state!(:prediction, prediction)
    end

    private

    def form? = prediction.present? && (default? || error?)

    def form_url
      return pool_bet_path(prediction.pool_id, prediction) if prediction.persisted?

      pool_bets_path(prediction.pool_id)
    end

    def submit_label = prediction.persisted? ? 'Atualizar' : 'Palpitar'

    def field_error(attribute) = prediction.errors[attribute].first

    def base_errors = prediction&.errors&.[](:base).presence || ['Não foi possível salvar o palpite.']

    def saved_guess
      return if prediction.nil? || prediction.home_guess.nil? || prediction.away_guess.nil?

      "#{prediction.home_guess} × #{prediction.away_guess}"
    end

    def guess_input_classes
      'w-14 rounded-sm border border-rule px-2 py-1 text-center text-lg font-bold tabular-nums'
    end
  end
end
