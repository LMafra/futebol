module Bolao
  # Participantes › Bolão: the organizer removes a member, with the reason in the AuditLog. The member's predictions
  # in the pool and their points are discarded (kept for the history), so the ranking drops them at once.
  class MemberRemoval
    def self.call(membership:, reason:, actor:, ip_address:)
      predictions = Bolao::Prediction.kept.where(pool_id: membership.pool_id, user_id: membership.user_id)
      Bolao::PoolMembership.transaction do
        now = Time.current
        scores = Bolao::PredictionScore.kept.where(prediction: predictions).update_all(discarded_at: now)
        discarded = predictions.update_all(discarded_at: now)
        membership.destroy!
        Core::AuditLog.create!(action: 'bolao.member_removed', user: actor, auditable: membership.pool, ip_address:,
                               metadata: { user_id: membership.user_id, reason:, predictions_discarded: discarded,
                                           scores_discarded: scores })
      end
    end
  end
end
