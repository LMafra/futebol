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

    # Specs hand in matches that already kicked off: the prediction itself was placed before kickoff.
    to_create { |prediction| prediction.save!(context: :backfill) }
  end

  factory :bolao_prediction_score, class: 'Bolao::PredictionScore' do
    prediction factory: :bolao_prediction
    points { 10 }
    scoring_token { SecureRandom.uuid }
  end

  factory :bolao_scoring_rule, class: 'Bolao::ScoringRule' do
    exact_score_points { 10 }
    winner_points { 5 }
  end

  factory :cartola_squad, class: 'Cartola::Squad' do
    user
    sequence(:name) { |n| "Esquadrão #{n}" }
  end

  # A full lineup (bypassing the wallet): include_players are kept and every slot is filled up to the
  # championship's limits with new players.
  factory :cartola_lineup, class: 'Cartola::Lineup' do
    transient do
      include_players { [] }
    end

    squad factory: :cartola_squad
    championship
    round { 1 }
    formation { '4-3-3' }
    players do
      missing = championship.cartola_limits.transform_keys(&:to_s)
      include_players.each { |player| missing[player.slot] -= 1 }
      fill_positions = { 'goalkeeper' => 'GOL', 'defender' => 'ZAG', 'midfielder' => 'MEI', 'forward' => 'ATA' }
      include_players + missing.flat_map do |slot, count|
        Array.new(count) { association(:player, position: fill_positions.fetch(slot)) }
      end
    end
  end

  factory :cartola_wallet, class: 'Cartola::Wallet' do
    user
    championship
    balance { 100 }
  end

  factory :cartola_player_value, class: 'Cartola::PlayerValue' do
    player
    championship
    value { 5 }
    changed_at { Time.current }
  end

  factory :cartola_player_score, class: 'Cartola::PlayerScore' do
    player
    match
    team { player.team }
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
