# The "Corrigir palpite" dialog of Participantes › Bolão: new guesses and the reason (Bolao::PredictionCorrection).
class PredictionCorrectionForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :prediction_id, :integer
  attribute :home_guess, :integer
  attribute :away_guess, :integer
  attribute :reason, :string
  attr_accessor :pool, :actor, :ip_address

  validates :home_guess, :away_guess, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :reason, presence: { message: 'é obrigatório: fica registrado na auditoria' }
  validate :prediction_in_pool

  def self.model_name = ActiveModel::Name.new(self, nil, 'Correction')

  def self.human_attribute_name(attribute, _options = {})
    { home_guess: 'Mandante', away_guess: 'Visitante', reason: 'Motivo' }.fetch(attribute.to_sym, attribute.to_s)
  end

  def prediction
    @prediction ||= pool && Bolao::Prediction.kept.includes(match: %i[home_team away_team])
                                             .find_by(id: prediction_id, pool:)
  end

  def save
    return false unless valid?

    Bolao::PredictionCorrection.call(prediction:, guess: [home_guess, away_guess], reason:, actor:, ip_address:)
    true
  end

  private

  def prediction_in_pool
    errors.add(:base, 'Palpite não encontrado neste bolão.') unless prediction
  end
end
