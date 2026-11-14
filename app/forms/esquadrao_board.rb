# Participantes › Esquadrão (/admin and /gestor): for a championship and a round, the ranking, the round's answer
# key (the points of each real player and the ideal lineup) and every participant's lineup with its points.
# Points follow Cartola::RankingsService: kept PlayerScore points of the round's matches, the captain's twice.
class EsquadraoBoard
  PlayerRow = Data.define(:player, :points)
  Ideal = Data.define(:players, :captain) do
    def total = players.sum(&:points) + (captain&.points || 0)
    def empty? = players.empty?

    # "2-3-3": defenders, midfielders and forwards picked.
    def formation
      counts = players.map { _1.player.slot }.tally
      %w[defender midfielder forward].map { counts.fetch(_1, 0) }.join('-')
    end
  end
  Entry = Data.define(:lineup, :points) do
    def id = lineup.id
    def user = lineup.squad.user
    def name = user.name.presence || user.email_address
  end

  attr_reader :championship, :round

  def initialize(championship, round: nil)
    @championship = championship
    @round = (round.presence || default_round).to_i.clamp(1, 38)
  end

  def rounds = @rounds ||= matches.where.not(round: nil).distinct.order(:round).pluck(:round)
  def ranking = @ranking ||= Cartola::RankingsService.points(championship)
  def coins = @coins ||= Cartola::RankingsService.coins(championship)

  # Every player who scored in the round, best first.
  def answer_key
    @answer_key ||= Core::Player.where(id: round_points.keys).includes(:team).to_a
                                .map { PlayerRow.new(player: _1, points: round_points.fetch(_1.id)) }
                                .sort_by { [-_1.points, _1.player.name] }
  end

  # The best lineup the round allowed: for each formation, capped by the championship's limits, the best players
  # with points per slot; the captain is the best of them.
  def ideal = @ideal ||= Cartola::Lineup::FORMATIONS.map { ideal_for(_1) }.max_by(&:total)

  def entries
    @entries ||= Cartola::Lineup.where(championship:, round:)
                                .includes(squad: :user, lineup_players: { player: :team }).to_a
                                .map { Entry.new(lineup: _1, points: lineup_points(_1)) }
                                .sort_by { [-_1.points, _1.name.downcase] }
  end

  def find(lineup_id) = entries.find { _1.id.to_s == lineup_id.to_s }
  def points_of(player) = round_points.fetch(player.id, 0)

  # { player_id => points } as the ranking counts them: the captain's twice.
  def counted_points(lineup)
    lineup.lineup_players.to_h do |lineup_player|
      [lineup_player.player_id, (lineup_player.captain ? 2 : 1) * points_of(lineup_player.player)]
    end
  end

  # What the organizer may pick: the championship's players plus those already in the lineup.
  def candidates(lineup)
    Core::Player.where(team: championship.teams).or(Core::Player.where(id: lineup.lineup_players.map(&:player_id)))
                .includes(:team).order(:name).to_a.group_by { _1.slot.to_sym }
  end

  private

  def matches = Core::Match.where(championship:)
  def default_round = matches.where(status: 'scored').maximum(:round) || rounds.first || 1

  def round_points
    @round_points ||= Cartola::PlayerScore.kept.joins(:match)
                                          .where(core_matches: { championship_id: championship.id, round: })
                                          .group(:player_id).sum(:points)
  end

  def lineup_points(lineup) = counted_points(lineup).values.sum

  def scorers_by_slot
    @scorers_by_slot ||= answer_key.select { _1.points.positive? }.group_by { _1.player.slot.to_sym }
  end

  def ideal_for(formation)
    slots = Cartola::Lineup.new(championship:, formation:).slots
    players = slots.flat_map { |slot, count| scorers_by_slot.fetch(slot, []).first(count) }
    Ideal.new(players:, captain: players.max_by(&:points))
  end
end
