# Admin "MatchReversal": reverting the points of a match always requires a written reason, kept in the AuditLog.
class MatchReversalForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :reason, :string
  attr_accessor :match, :actor, :ip_address

  validates :reason, presence: { message: 'é obrigatório' }, length: { maximum: 500 }
  validate :match_can_revert

  def self.model_name = ActiveModel::Name.new(self, nil, 'Reversal')

  def save
    return false unless valid?

    RevertMatchPointsJob.perform_later(match.id, SecureRandom.uuid, ip_address:, actor_id: actor&.id,
                                                                    reason: reason.strip)
    true
  end

  private

  def match_can_revert
    return if match.nil? || match.may_revert_match?

    errors.add(:base, "A partida está #{match.status} e sem pontuação calculada: nada para reverter")
  end
end
