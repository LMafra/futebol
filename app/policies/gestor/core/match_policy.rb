module Gestor
  module Core
    class MatchPolicy < ::Core::MatchPolicy
      def create?
        admin? || (manager? && (!record_instance? || ((record.championship.nil? || manage?) && teams_visible?)))
      end

      def update? = (admin? || (manage? && teams_visible?)) && record_instance? && record.scheduled?

      def record_scouts? = admin? || manage?
      def finalize? = admin? || manage?
      def revert? = admin? || manage?

      private

      def teams_visible?
        team_ids = [record.home_team_id, record.away_team_id].compact.uniq
        ::Core::TeamPolicy::Scope.new(user, ::Core::Team.where(id: team_ids)).resolve.count == team_ids.size
      end
    end
  end
end
