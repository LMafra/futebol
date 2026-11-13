module Gestor
  module Bolao
    class PoolPolicy < ::Bolao::PoolPolicy
      def index? = admin? || manager?
      def show? = admin? || manager?
      def update? = false
      def edit? = false
      def destroy? = false
      def destroy_all? = false
      def manage? = false

      class Scope < ApplicationPolicy::Scope
        private

        def managed_scope = scope.where(championship_id: managed_championships.select(:id))
      end
    end
  end
end
