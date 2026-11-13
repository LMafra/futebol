# The "Editar escalação" form of Participantes › Esquadrão: players, captain, formation and the reason
# (Cartola::LineupCorrection).
class LineupCorrectionForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :formation, :string
  attribute :captain_id, :integer
  attribute :reason, :string
  attr_accessor :lineup, :actor, :ip_address
  attr_writer :player_ids

  validates :reason, presence: { message: 'é obrigatório: fica registrado na auditoria' }

  def self.model_name = ActiveModel::Name.new(self, nil, 'Lineup')
  def self.human_attribute_name(attribute, _options = {}) = attribute.to_s == 'reason' ? 'Motivo' : attribute.to_s

  def player_ids = Array(@player_ids).compact_blank.map(&:to_i)

  def save
    return false unless valid?
    return true if Cartola::LineupCorrection.call(lineup:, picks: { formation:, captain_id:, player_ids: },
                                                  reason:, actor:, ip_address:)

    lineup.errors.full_messages.each { errors.add(:base, _1) }
    false
  end
end
