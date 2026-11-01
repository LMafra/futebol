# Admin "MatchFinalizer": the final score must be typed twice — once in the score fields and once,
# as "2x1", in score_confirmation — before the match is finished and scored.
class MatchFinalizationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  GOALS = /\A\d{1,2}\z/

  attribute :home_score, :string
  attribute :away_score, :string
  attribute :score_confirmation, :string
  attr_accessor :match, :actor, :ip_address

  validates :home_score, :away_score, format: { with: GOALS, message: 'deve ser um número inteiro de 0 a 99' }
  validates :score_confirmation, presence: { message: 'é obrigatória: digite o placar final para confirmar' }
  validate :confirmation_matches_score, if: -> { errors.none? }
  validate :match_can_finish

  def self.model_name = ActiveModel::Name.new(self, nil, 'Finalization')

  def expected_confirmation = "#{home_score}x#{away_score}"

  def save
    return false unless valid?

    FinalizeMatchService.call(match:, home_score: Integer(home_score, 10), away_score: Integer(away_score, 10),
                              actor:, ip_address:)
    true
  end

  private

  def confirmation_matches_score
    typed = score_confirmation.to_s.downcase.delete(' ').tr('×', 'x')
    return if typed == expected_confirmation

    errors.add(:score_confirmation, "não confere com o placar informado (digite #{expected_confirmation})")
  end

  def match_can_finish
    return if match.nil? || match.live? || match.may_start_match?

    errors.add(:base, "A partida está #{match.status}: só partidas ao vivo ou já iniciadas podem ser finalizadas")
  end
end
