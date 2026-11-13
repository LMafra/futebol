# The single match page of /admin and /gestor (TICKET-0097): each side's players (goalkeepers first) with their kept
# scouts, the kept lances newest first, and the period suggested for the next lance.
class MatchBoard
  Line = Data.define(:player, :score) do
    def goalkeeper? = player.position == 'GOL'
    def team_id = score&.team_id || player.team_id
    def count(stat) = score ? score.public_send(stat) : 0
    def played? = score&.played || false
    def highlight? = score&.highlight || false

    # The stats a player can get a lance in: DE only for goalkeepers (Scouts::EventRules).
    def stats = Cartola::PlayerScore::SCOUTS.reject { |stat| stat == :saves && !goalkeeper? }
  end

  Side = Data.define(:key, :label, :team, :lines)

  POSITION_ORDER = Core::Player::POSITIONS.each_with_index.to_h.freeze

  attr_reader :match

  def initialize(match)
    @match = match
    crest = { crest_attachment: :blob }
    associations = [:championship, { home_team: crest, away_team: crest }]
    ActiveRecord::Associations::Preloader.new(records: [match], associations:).call
  end

  def sides
    [['home', 'Mandante', match.home_team], ['away', 'Visitante', match.away_team]].map do |key, label, team|
      Side.new(key:, label:, team:, lines: lines.select { |line| line.team_id == team.id })
    end
  end

  def events
    @events ||= Cartola::ScoutEvent.timeline(match)
  end

  def default_period = events.find(&:period)&.period || 'first_half'

  def derived_score = Cartola::PlayerScore.score_for(match)

  def rule_missing? = !Cartola::ScoringRule.exists?(name: Cartola::ScoringRule::DEFAULT_NAME)

  private

  def lines
    @lines ||= players.sort_by { |player| [POSITION_ORDER.fetch(player.position, 99), player.name] }
                      .map { |player| Line.new(player:, score: scores[player.id]) }
  end

  def scores = @scores ||= Cartola::PlayerScore.kept.where(match:).index_by(&:player_id)

  def players
    Core::Player.where(team_id: [match.home_team_id, match.away_team_id]).or(Core::Player.where(id: scores.keys)).to_a
  end
end
