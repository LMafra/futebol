module Gestor
  module Cartola
    class LineupPolicy < ::Cartola::LineupPolicy
      def index? = admin? || manager?
      def show? = admin? || manager?
      def create? = false
      def new? = false
      def update? = false
      def edit? = false
      def destroy? = false
      def correct? = admin? || (record_instance? && manages?(record.championship))

      class Scope < ApplicationPolicy::Scope
        private

        def managed_scope = scope.where(championship_id: managed_championships.select(:id))
      end
    end
  end
end
