module Core
  class TeamPolicy < ApplicationPolicy
    def index? = admin? || manager?
    def create? = admin? || manager?
    def show? = admin? || (manager? && record_instance? && visible_to_manager?)
    def update? = admin? || manage?
    def destroy? = update?
    def manage? = manager? && record_instance? && record.championships.not_managed_by(user).none?

    private

    def visible_to_manager? = record.championships.none? || record.championships.exists?(manager_id: user.id)

    class Scope < ApplicationPolicy::Scope
      def locked_ids
        return [] if user&.admin?

        Core::Team.playing_in(Core::Championship.not_managed_by(user)).pluck(:id)
      end

      private

      def managed_scope
        scope.where(id: Core::Team.playing_in(managed_championships).or(Core::Team.without_matches).select(:id))
      end
    end
  end
end
