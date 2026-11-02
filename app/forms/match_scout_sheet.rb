# Admin "Scouts da partida": one line per player of both sides (goalkeepers first), filled with the kept scouts,
# or with the values just submitted when the service rejected them.
class MatchScoutSheet
  Line = Data.define(:player, :team_id, :values, :points) do
    def goalkeeper? = player.position == 'GOL'
  end

  POSITION_ORDER = Core::Player::POSITIONS.each_with_index.to_h.freeze
  EMPTY_VALUES = Cartola::PlayerScore::SCOUTS.index_with(0).merge(played: false, highlight: false,
                                                                  clean_sheet: false).freeze

  attr_reader :match

  # submitted: the rows given to Cartola::RecordScoutsService, when re-rendering after an error.
  def initialize(match:, submitted: nil)
    @match = match
    @submitted = submitted&.index_by { |row| row[:player_id].to_i }
  end

  def readonly? = match.scored?

  def lines_for(team) = lines.select { |line| line.team_id == team.id }

  def highlight_player_id = lines.find { |line| line.values[:highlight] }&.player&.id

  def rule
    return @rule if defined?(@rule)

    @rule = Cartola::ScoringRule.find_by(name: Cartola::ScoringRule::DEFAULT_NAME)
  end

  # { stat => points per unit } for the in-browser preview; penalties are negative (Cartola::Scorer).
  def preview_weights
    return {} unless rule

    { Cartola::Scorer::BONUSES => 1, Cartola::Scorer::PENALTIES => -1, Cartola::Scorer::FLAGS => 1 }
      .reduce({}) do |weights, (columns, sign)|
        weights.merge(columns.transform_values { |column| sign * rule.public_send(column).to_f })
      end
  end

  private

  def lines
    @lines ||= players.sort_by { |player| [POSITION_ORDER.fetch(player.position, 99), player.name] }.map do |player|
      line_for(player, scores[player.id])
    end
  end

  def line_for(player, score)
    submitted = @submitted&.dig(player.id)
    return submitted_line(player, submitted, score) if submitted

    Line.new(player:, team_id: score&.team_id || player.team_id, points: score&.points,
             values: score ? EMPTY_VALUES.merge(score.stats) : EMPTY_VALUES)
  end

  def submitted_line(player, row, score)
    values = EMPTY_VALUES.merge(Cartola::PlayerScore::SCOUTS.to_h { |scout| [scout, row[scout].to_i] })
                         .merge(played: ActiveModel::Type::Boolean.new.cast(row[:played]) || false,
                                highlight: row[:highlight] || false)
    Line.new(player:, team_id: row[:team_id].to_i, values:, points: score&.points)
  end

  def scores = @scores ||= Cartola::PlayerScore.kept.where(match:).index_by(&:player_id)

  def players
    sides = [match.home_team_id, match.away_team_id]
    Core::Player.where(team_id: sides).or(Core::Player.where(id: scores.keys)).to_a
  end
end
