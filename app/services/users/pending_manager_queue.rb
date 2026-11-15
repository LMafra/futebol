module Users
  # Admin triage queue: pending manager requests, oldest first, so requests waiting more than a day lead.
  class PendingManagerQueue
    OVERDUE_AFTER = 24.hours

    Entry = Data.define(:user, :requested_at) do
      def overdue?(now = Time.current) = requested_at <= now - OVERDUE_AFTER
    end

    def self.call = new.call

    def call
      users = Core::User.where(manager_status: :pending).to_a
      requested = requested_at_by_user_id(users.map(&:id))
      users.map { |user| Entry.new(user:, requested_at: requested.fetch(user.id, user.updated_at)) }
           .sort_by { |entry| [entry.requested_at, entry.user.id] }
    end

    private

    def requested_at_by_user_id(ids)
      return {} if ids.empty?

      Core::AuditLog.where(action: 'user.manager_requested', auditable_type: Core::User.polymorphic_name,
                           auditable_id: ids)
                    .group(:auditable_id).maximum(:created_at)
    end
  end
end
