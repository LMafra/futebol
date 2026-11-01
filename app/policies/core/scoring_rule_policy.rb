module Core
  # Scoring rules are stored per game (Bolao::ScoringRule, Cartola::ScoringRule); both policies inherit from this one.
  class ScoringRulePolicy < ApplicationPolicy
    def test? = admin?
  end
end
