# Public home: hero, counters, modules, how it works, today's matches, the public championships with the leaders
# of their table and their Top 3 rankings, and the top 10 athletes. The counters cover every championship; the
# lists show only public ones, to visitors and users alike, and are loaded in grouped queries whatever the number
# of championships.
class HomeController < ApplicationController
  FINAL_STATUSES = %w[finished scored].freeze

  allow_unauthenticated_access
  skip_after_action :verify_policy_scoped

  def index
    load_home_payload
  end

  private

  def load_home_payload
    public_championships = Core::Championship.publicly_visible
    @championships = public_championships.with_attached_logo.order(season: :desc, name: :asc).to_a
    public_matches = Core::Match.where(championship: public_championships)
    assign_home_collections(public_matches)
    @participating_championship_ids = participating_championship_ids
  end

  def assign_home_collections(public_matches)
    @counters = { championships: Core::Championship.published.count, matches: Core::Match.count,
                  players: Core::Player.count }
    @matches_today = matches_today(public_matches)
    @standings = Core::ChampionshipStandingsService.top(@championships)
    @rankings = Core::ChampionshipRankingsService.top(@championships)
    @championship_facts = championship_facts(public_matches)
    @top_players = Cartola::TopPlayersService.call(@championships)
  end

  def participating_championship_ids
    return Set.new unless current_user

    Set.new(pool_championship_ids + lineup_championship_ids)
  end

  def pool_championship_ids
    Bolao::Pool.joins(:memberships)
               .where(bolao_pool_memberships: { user_id: current_user.id })
               .distinct.pluck(:championship_id)
  end

  def lineup_championship_ids
    squad = Cartola::Squad.find_by(user: current_user)
    return [] unless squad

    squad.lineups.distinct.pluck(:championship_id)
  end

  def matches_today(matches)
    matches.where(match_date: Date.current.all_day).includes(:championship, :home_team, :away_team)
           .order(:match_date, :id).to_a
  end

  # { championship_id => { teams:, status: } }
  def championship_facts(matches)
    teams = team_counts(matches)
    statuses = statuses_by_championship(matches)
    @championships.to_h do |championship|
      [championship.id, { teams: teams.fetch(championship.id, 0), status: status_label(statuses[championship.id]) }]
    end
  end

  def team_counts(matches)
    matches.pluck(:championship_id, :home_team_id, :away_team_id).group_by(&:first)
           .transform_values { |rows| rows.flat_map { |row| row.drop(1) }.uniq.size }
  end

  def statuses_by_championship(matches)
    matches.distinct.pluck(:championship_id, :status).group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
  end

  def status_label(statuses)
    return 'Sem partidas' if statuses.blank?
    return 'Encerrado' if statuses.all? { |status| status.in?(FINAL_STATUSES) }
    return 'A começar' if statuses.all?('scheduled')

    'Em andamento'
  end
end
