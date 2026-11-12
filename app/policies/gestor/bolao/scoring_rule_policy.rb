module Gestor
  module Bolao
    class ScoringRulePolicy < ::Bolao::ScoringRulePolicy
      def index? = admin? || manager?
      def show? = index?
      def create? = manage?
      def update? = manage?
      def destroy? = manage?

      def manage?
        return false unless record_instance? && record.pool_id.nil?

        championship = record.championship || ::Core::Championship.find_by(id: record.championship_id)
        championship.present? && manages?(championship)
      end

      class Scope < ApplicationPolicy::Scope
        private

        def managed_scope = scope.where(pool_id: nil, championship_id: managed_championships.select(:id))
      end
    end
  end
end
