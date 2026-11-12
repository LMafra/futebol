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

    def field_errors = %i[home_guess away_guess].filter_map { prediction.errors[_1].first }.uniq

    def error_id = "prediction-error-#{prediction.match_id || prediction.id}"

    def guess_aria(label)
      { label:, invalid: field_errors.any? || nil, describedby: (error_id if field_errors.any?) }
    end

    def base_errors = prediction&.errors&.[](:base).presence || ['Não foi possível salvar o palpite.']

    def saved_guess
      return if prediction.nil? || prediction.home_guess.nil? || prediction.away_guess.nil?

      "#{prediction.home_guess} × #{prediction.away_guess}"
    end

    def guess_input_classes
      form_control_classes('w-16 text-center text-lg font-bold tabular-nums', invalid: field_errors.any?)
    end
  end
end
