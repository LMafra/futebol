FactoryBot.define do
  factory :bolao_scoring_rule, class: 'Bolao::ScoringRule' do
    kind { 'exact_score' }
    points { 10 }
  end

  factory :cartola_scoring_rule, class: 'Cartola::ScoringRule' do
    sequence(:name) { |n| "regra-#{n}" }
    goal_points { 8 }
    assist_points { 5 }
    yellow_card_penalty { 1 }
    red_card_penalty { 3 }
  end
end
