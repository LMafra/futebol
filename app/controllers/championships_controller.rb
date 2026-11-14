# Public page of a championship (/campeonatos/:id), open to visitors; a private championship is a 404.
#   ?tab=times (default): standings from the finished matches;
#   ?tab=partidas: every match grouped by round, with one round open (?rodada=, default the first round still open,
#                  else the last);
#   ?tab=bolao, ?tab=esquadrao: the full public rankings (Core::ChampionshipRankingsService).
class ChampionshipsController < ApplicationController
  TABS = { 'times' => 'Times', 'partidas' => 'Partidas', 'bolao' => 'Bolão', 'esquadrao' => 'Esquadrão' }.freeze
  # Fixed partial per tab, so the rendered path never comes from the request.
  PARTIALS = TABS.keys.index_with { |tab| "championships/#{tab}" }.freeze
  FINAL_STATUSES = %w[finished scored].freeze
  OPEN_STATUSES = %w[scheduled live].freeze

  allow_unauthenticated_access

  def show
    @championship = Core::Championship.publicly_visible.find(params[:id])
    authorize @championship, :public_show?
    @tab = TABS.key?(params[:tab]) ? params[:tab] : TABS.keys.first
    load_tab
  end

  private

  def load_tab
    case @tab
    when 'times' then load_standings
    when 'partidas' then load_round
    when 'bolao' then @ranking = Core::ChampionshipRankingsService.bolao(@championship)
    when 'esquadrao' then @ranking = Core::ChampionshipRankingsService.esquadrao(@championship)
    end
  end

  def load_standings
    matches = @championship.matches.with_team_crests.to_a
    @teams = matches.flat_map { |match| [match.home_team, match.away_team] }.uniq.sort_by(&:name)
    @standings = Simulador::StandingsCalculator.call(
      matches: matches.select { |match| match.status.in?(FINAL_STATUSES) },
      teams: @teams.to_h { |team| [team.id, team.name] }
    )
  end

  def load_round
    @matches = @championship.matches.includes(:home_team, :away_team).order(:round, :match_date, :id).to_a
    rounds = @matches.filter_map(&:round).uniq
    @round = params[:rodada].to_i.presence_in(rounds) || current_round || rounds.last
  end

  def current_round = @matches.find { |match| match.round && match.status.in?(OPEN_STATUSES) }&.round
end
