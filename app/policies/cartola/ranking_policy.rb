module Cartola
  # Headless (authorize [:cartola, :ranking]): every signed-in user sees the Cartola rankings.
  class RankingPolicy < ApplicationPolicy
    def show? = user.present?
  end
end
