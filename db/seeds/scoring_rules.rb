module Seeds
  def self.scoring_rules
    { exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3 }.each do |kind, points|
      Bolao::ScoringRule.find_or_create_by!(pool_id: nil, kind:) { |rule| rule.points = points }
    end

    Cartola::ScoringRule.find_or_create_by!(name: Cartola::ScoringRule::DEFAULT_NAME) do |rule|
      rule.assign_attributes(goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)
    end
  end
end
