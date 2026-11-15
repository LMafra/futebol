# The "Remover do bolão" dialog of Participantes › Bolão: the member and the reason (Bolao::MemberRemoval).
class MemberRemovalForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_id, :integer
  attribute :reason, :string
  attr_accessor :pool, :actor, :ip_address

  validates :reason, presence: { message: 'é obrigatório: fica registrado na auditoria' }
  validate :member_of_pool

  def self.model_name = ActiveModel::Name.new(self, nil, 'Removal')
  def self.human_attribute_name(attribute, _options = {}) = attribute.to_s == 'reason' ? 'Motivo' : attribute.to_s

  def membership = @membership ||= pool&.memberships&.find_by(user_id:)

  def save
    return false unless valid?

    Bolao::MemberRemoval.call(membership:, reason:, actor:, ip_address:)
    true
  end

  private

  def member_of_pool
    errors.add(:base, 'Participante não encontrado neste bolão.') unless membership
  end
end
