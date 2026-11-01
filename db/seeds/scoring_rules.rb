module Seeds
  def self.scoring_rules
    Bolao::ScoringRule.find_or_create_by!(pool_id: nil, championship_id: nil) do |rule|
      rule.assign_attributes(exact_score_points: 10, winner_points: 5)
    end

    Cartola::ScoringRule.find_or_create_by!(name: Cartola::ScoringRule::DEFAULT_NAME) do |rule|
      rule.assign_attributes(goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)
    end
  end
end
