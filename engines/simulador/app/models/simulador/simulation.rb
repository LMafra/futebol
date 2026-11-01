module Simulador
  # A "what if" in memory (ADR 0003 §3): hypothetical scores for the open matches of a championship.
  # Never persisted. guesses: { match_id => { home:, away: } }; errors: { match_id => message }.
  Simulation = Data.define(:championship_id, :guesses, :errors) do
    # raw: { "match_id" => { "home" => "2", "away" => "1" } }, as posted by the form.
    def self.parse(raw, championship_id:, editable_ids:)
      guesses = {}
      errors = {}
      raw.each do |key, score|
        match_id = Integer(key.to_s, 10, exception: false)
        result = editable_ids.include?(match_id) ? guess(score) : 'não é uma partida em aberto deste campeonato'
        guesses[match_id] = result if result.is_a?(Hash)
        errors[key.to_s] = result if result.is_a?(String)
      end
      new(championship_id:, guesses:, errors:)
    end

    # nil when both sides are blank (the match stays out), an error message, or { home:, away: }.
    def self.guess(score)
      home, away = %w[home away].map { |side| goals(score[side]) }
      return if home == :blank && away == :blank
      return 'placar inválido: use números inteiros de 0 a 99' unless home.is_a?(Integer) && away.is_a?(Integer)

      { home:, away: }
    end

    def self.goals(value)
      return :blank if value.to_s.strip.empty?

      goals = Integer(value.to_s.strip, 10, exception: false)
      goals if goals&.between?(0, 99)
    end

    private_class_method :guess, :goals

    def valid? = errors.empty?
  end
end
