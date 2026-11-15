# Finalização on the match page (Admin and Gestor): the final score comes from the official scouts
# (Cartola::PlayerScore.score_for) and is read-only; confirming the dialog finishes the match and scores it in the
# same request (FinalizeMatchService). Without scouts the match cannot be finalized.
class MatchFinalizationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  NO_SCOUTS = 'Registre os lances antes de finalizar'.freeze

  attr_accessor :match, :actor, :ip_address

  validate :scouts_recorded
  validate :match_can_finish

  def self.model_name = ActiveModel::Name.new(self, nil, 'Finalization')

  def derived_score
    return @derived_score if defined?(@derived_score)

    @derived_score = match && Cartola::PlayerScore.score_for(match)
  end

  def scouts? = !derived_score.nil?

  def home_score = derived_score&.first
  def away_score = derived_score&.last

  def pool_participants_count
    return 0 if match.nil?

    Bolao::PoolMembership.joins(:pool).where(bolao_pools: { championship_id: match.championship_id }).count
  end

  def impact_summary
    count = pool_participants_count
    "#{count} #{count == 1 ? 'participante' : 'participantes'} do Bolão serão pontuados"
  end

  def save
    return false unless valid?

    FinalizeMatchService.call(match:, home_score:, away_score:, actor:, ip_address:)
    true
  end

  private

  def scouts_recorded
    errors.add(:base, NO_SCOUTS) if match && !scouts?
  end

  def match_can_finish
    return if match.nil? || FinalizeMatchService.finalizable?(match)

    status = Ui::StatusBadgeComponent::LABELS.fetch(match.status.to_sym).downcase
    errors.add(:base, "A partida está #{status}: só partidas ao vivo, encerradas ou revertidas podem ser finalizadas")
  end
end
