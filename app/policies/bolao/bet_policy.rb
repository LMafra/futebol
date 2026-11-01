module Bolao
  # Bets are Bolao::Prediction records placed through Bolao::BetsController (policy_class: Bolao::BetPolicy).
  class BetPolicy < ApplicationPolicy
    def create? = own_bet? && record.pool.member?(user)
    def update? = create?

    private

    def own_bet? = user.present? && record.user_id == user.id

    class Scope < ApplicationPolicy::Scope
      def resolve
        return scope.none if user.nil?

        scope.kept.where(user_id: user.id)
      end
    end
  end
end
