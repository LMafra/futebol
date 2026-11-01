module Simulador
  # Public "what if" standings (ADR 0003). GET shows the real table and the open (scheduled/live) matches of a
  # championship (?championship_id= or /simulador/:championship_id, default the latest); POST projects the table
  # with the guessed scores into the "simulador" Turbo Frame. Nothing is stored.
  # ::ApplicationController: inside Simulador, the bare constant resolves to the engine's controller.
  class SimulationsController < ::ApplicationController
    EDITABLE_STATUSES = %w[scheduled live].freeze

    allow_unauthenticated_access
    rate_limit to: 30, within: 1.minute, by: -> { request.remote_ip }, only: :preview,
               with: -> { reject_rate_limited_preview }

    before_action :set_championship

    def show
      authorize %i[simulador simulation], :show?
      return unless stale?(etag: [@championship, @championship.matches.maximum(:updated_at), @championships.size])

      load_matches
      @simulation = Simulador::Simulation.new(championship_id: @championship.id, guesses: live_scores, errors: {})
    end

    def preview
      authorize %i[simulador simulation], :preview?
      load_matches
      @raw = guess_params
      @simulation = Simulador::Simulation.parse(@raw, championship_id: @championship.id,
                                                      editable_ids: @open_matches.map(&:id))
      @projected = project(@simulation.guesses) if @simulation.valid?
      render :preview, status: @simulation.valid? ? :ok : :unprocessable_content
    end

    private

    def set_championship
      @championships = Core::Championship.order(season: :desc, name: :asc).to_a
      @championship = if params[:championship_id].present?
                        @championships.find { |championship| championship.id == params[:championship_id].to_i }
                      else
                        @championships.first
                      end
      raise ActiveRecord::RecordNotFound, 'Campeonato não encontrado' unless @championship
    end

    def load_matches
      matches = @championship.matches.includes(:home_team, :away_team).order(:round, :match_date, :id).to_a
      @teams = teams_of(matches)
      @open_matches = matches.select { |match| match.status.in?(EDITABLE_STATUSES) }
      @fixtures = matches.map { |match| fixture(match) }
      @real = calculate({})
    end

    def teams_of(matches) = matches.flat_map { |match| [match.home_team, match.away_team] }.uniq.sort_by(&:name)

    # Open matches only count through a guess, so a live score does not leak into the real table.
    def fixture(match)
      open = match.status.in?(EDITABLE_STATUSES)
      Simulador::StandingsCalculator::Fixture.new(
        id: match.id, home_team_id: match.home_team_id, away_team_id: match.away_team_id,
        home_score: (match.home_score unless open), away_score: (match.away_score unless open)
      )
    end

    def calculate(overrides)
      Simulador::StandingsCalculator.call(matches: @fixtures, teams: @teams.to_h { |team| [team.id, team.name] },
                                          overrides:)
    end

    def project(guesses)
      real_positions = @real.to_h { |standing| [standing.team_id, standing.position] }
      calculate(guesses).map { |standing| [standing, real_positions.fetch(standing.team_id) - standing.position] }
    end

    def live_scores
      @open_matches.select(&:live?).to_h { |match| [match.id, { home: match.home_score, away: match.away_score }] }
    end

    def guess_params
      guesses = params.fetch(:guesses, {})
      return {} unless guesses.respond_to?(:each_pair)

      guesses.keys.index_with do |key|
        score = guesses[key]
        score.respond_to?(:permit) ? score.permit(:home, :away).to_h : {}
      end
    end

    def reject_rate_limited_preview
      Rails.logger.warn("rate_limited #{controller_name}##{action_name} ip=#{request.remote_ip}")
      render :rate_limited, status: :too_many_requests
    end
  end
end
