FactoryBot.define do
  factory :bolao_pool, class: 'Bolao::Pool' do
    championship
    owner factory: :user
    sequence(:name) { |n| "Bolão #{n}" }
  end

  factory :bolao_prediction, class: 'Bolao::Prediction' do
    pool factory: :bolao_pool
    user
    match
    home_guess { 1 }
    away_guess { 0 }
  end

  factory :bolao_prediction_score, class: 'Bolao::PredictionScore' do
    prediction factory: :bolao_prediction
    points { 10 }
    scoring_token { SecureRandom.uuid }
  end

  factory :bolao_scoring_rule, class: 'Bolao::ScoringRule' do
    kind { 'exact_score' }
    points { 10 }
  end

  factory :cartola_squad, class: 'Cartola::Squad' do
    user
    sequence(:name) { |n| "Esquadrão #{n}" }
  end

  factory :cartola_lineup, class: 'Cartola::Lineup' do
    squad factory: :cartola_squad
    round { 1 }
  end

  factory :cartola_player_score, class: 'Cartola::PlayerScore' do
    player
    match
    points { 5 }
  end

  factory :cartola_scoring_rule, class: 'Cartola::ScoringRule' do
    sequence(:name) { |n| "regra-#{n}" }
    goal_points { 8 }
    assist_points { 5 }
    yellow_card_penalty { 1 }
    red_card_penalty { 3 }
  end
end
