# Participantes › Bolão (/admin and /gestor pool page): the members with their points, the ranking and one member's
# predictions with the points of each.
class PoolParticipants
  Member = Data.define(:membership, :points, :predictions_count) do
    def id = membership.user_id
    def user = membership.user
    def name = user.name.presence || user.email_address
  end

  Standing = Data.define(:position, :member)
  Row = Data.define(:prediction, :points)

  attr_reader :pool

  def initialize(pool)
    @pool = pool
  end

  def members
    @members ||= pool.memberships.includes(:user).map { member_for(_1) }.sort_by { |member| member.name.downcase }
  end

  # Same points, same position ("1, 1, 3").
  def ranking
    sorted = members.sort_by { |member| [-member.points, member.name.downcase] }
    sorted.map { |member| Standing.new(position: sorted.index { _1.points == member.points } + 1, member:) }
  end

  def find(user_id) = members.find { |member| member.id.to_s == user_id.to_s }

  def predictions_for(member)
    predictions = Bolao::Prediction.kept.where(pool:, user_id: member.id)
                                   .includes(match: %i[home_team away_team]).to_a.sort_by { kickoff_order(_1) }
    points = Bolao::PredictionScore.kept.where(prediction: predictions).group(:prediction_id).sum(:points)
    predictions.map { |prediction| Row.new(prediction:, points: points[prediction.id]) }
  end

  private

  def member_for(membership)
    Member.new(membership:, points: totals.fetch(membership.user_id, 0),
               predictions_count: counts.fetch(membership.user_id, 0))
  end

  def kickoff_order(prediction) = [prediction.match.match_date || Time.zone.at(0), prediction.id]

  def totals
    @totals ||= Bolao::PredictionScore.kept.joins(:prediction).merge(Bolao::Prediction.kept)
                                      .where(bolao_predictions: { pool_id: pool.id })
                                      .group('bolao_predictions.user_id').sum(:points)
  end

  def counts = @counts ||= Bolao::Prediction.kept.where(pool:).group(:user_id).count
end
