ActiveAdmin.register_page 'ScoringRuleTester' do
  menu parent: 'Pontuação', label: 'Testar regras', priority: 4

  content title: 'Testar regras de pontuação' do
    render partial: 'admin/scoring_rule_tester/panels', locals: {
      pools: assigns[:pools], pool: assigns[:pool], bolao_rules: assigns[:bolao_rules],
      bolao: assigns[:bolao], cartola_rules: assigns[:cartola_rules], cartola: assigns[:cartola]
    }
  end

  controller do
    before_action :load_tester, only: :index

    private

    def load_tester
      authorize! :test, Bolao::ScoringRule
      load_rules
      @bolao = test_bolao if params[:bolao].present?
      @cartola = test_cartola if params[:cartola].present?
    end

    def load_rules
      @pools = Bolao::Pool.order(:name)
      pool_id = params.dig(:bolao, :pool_id)
      @pool = @pools.find_by(id: pool_id) if pool_id.present?
      @bolao_rules = Bolao::ScoringRule.for(@pool)
      @cartola_rules = Cartola::ScoringRule.order(:name)
    end

    def test_bolao
      input = params.expect(bolao: %i[pool_id guess_home guess_away result_home result_away])
      goals = input.slice(:guess_home, :guess_away, :result_home, :result_away).to_h.transform_values { goals(_1) }
      return { input:, error: 'Informe os quatro placares como números inteiros, a partir de 0.' } if goals.value?(nil)

      guess = goals.values_at('guess_home', 'guess_away')
      result = goals.values_at('result_home', 'result_away')
      { input:, kind: Scoring::BolaoScorer.outcome(guess:, result:),
        points: Scoring::Engine.score(:bolao, guess:, result:, rules: @bolao_rules) }
    rescue KeyError => e
      { input:, error: "Regra #{e.key} não cadastrada para este bolão." }
    end

    def test_cartola
      input = params.expect(cartola: %i[rule_id goals assists yellow_cards red_cards])
      rule = @cartola_rules.find_by(id: input[:rule_id])
      stats = input.slice(:goals, :assists, :yellow_cards, :red_cards).to_h.symbolize_keys
                   .transform_values { goals(_1) }
      return invalid_cartola(input) if rule.nil? || stats.value?(nil)

      { input:, rule:, points: Scoring::Engine.score(:cartola, stats:, rules: rule) }
    end

    def invalid_cartola(input) = { input:, error: 'Escolha uma regra e informe números inteiros, a partir de 0.' }

    def goals(value)
      number = Integer(value.to_s, 10, exception: false)
      number if number && !number.negative?
    end
  end
end
