# Admin "MatchFinalizer": the final score comes from the official scouts (Cartola::PlayerScore.score_for) and is
# read-only; the admin confirms it by typing it as "2x1" in score_confirmation before the match is finished and
# scored. Without scouts the match cannot be finalized.
class MatchFinalizationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  NO_SCOUTS = 'Lance os scouts antes de finalizar'.freeze

  attribute :score_confirmation, :string
  attr_accessor :match, :actor, :ip_address

  validate :scouts_recorded
  validates :score_confirmation, presence: { message: 'é obrigatória: digite o placar final para confirmar' }
  validate :confirmation_matches_score, if: -> { errors.none? }
  validate :match_can_finish

  def self.model_name = ActiveModel::Name.new(self, nil, 'Finalization')

  def derived_score
    return @derived_score if defined?(@derived_score)

    @derived_score = match && Cartola::PlayerScore.score_for(match)
  end

  def scouts? = !derived_score.nil?

  def home_score = derived_score&.first
  def away_score = derived_score&.last

  def expected_confirmation = "#{home_score}x#{away_score}"

  def save
    return false unless valid?

    FinalizeMatchService.call(match:, home_score:, away_score:, actor:, ip_address:)
    true
  end

  private

  def scouts_recorded
    errors.add(:base, NO_SCOUTS) if match && !scouts?
  end

  def confirmation_matches_score
    typed = score_confirmation.to_s.downcase.delete(' ').tr('×', 'x')
    return if typed == expected_confirmation

    errors.add(:score_confirmation, "não confere com o placar dos scouts (digite #{expected_confirmation})")
  end

  def match_can_finish
    return if match.nil? || match.live? || match.may_start_match?

    errors.add(:base, "A partida está #{match.status}: só partidas ao vivo ou já iniciadas podem ser finalizadas")
  end
end
