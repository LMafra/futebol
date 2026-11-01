module Bolao
  # ::ApplicationController: inside Bolao, the bare constant resolves to the engine's Bolao::ApplicationController.
  class BetsController < ::ApplicationController
    UPCOMING_LIMIT = 10

    rescue_from Pundit::NotAuthorizedError do |exception|
      render_forbidden(exception, message: 'Os palpites deste bolão são restritos aos participantes.')
    end

    before_action :set_pool

    def index
      authorize @pool, :show?
      render_index
    end

    def create
      match = Core::Match.where(championship_id: @pool.championship_id).find(params.dig(:prediction, :match_id))
      @prediction = @pool.predictions.build(guess_params.merge(user: current_user, match:))
      authorize @prediction, policy_class: Bolao::BetPolicy

      save_bet(notice: 'Palpite registrado.') { @prediction.save }
    end

    def update
      @prediction = @pool.predictions.kept.find(params[:id])
      authorize @prediction, policy_class: Bolao::BetPolicy

      save_bet(notice: 'Palpite atualizado.') { @prediction.update(guess_params) }
    end

    private

    def set_pool
      @pool = Bolao::Pool.find(params[:pool_id])
    end

    def guess_params
      params.expect(prediction: %i[home_guess away_guess])
    end

    def save_bet(notice:)
      if yield
        redirect_to pool_bets_path(@pool), notice:, status: :see_other
      else
        flash.now[:alert] = @prediction.errors.full_messages.to_sentence
        render_index(status: :unprocessable_content)
      end
    end

    def render_index(status: :ok)
      bets = my_bets.to_a
      @matches = open_matches
      @bets_by_match = bets.index_by(&:match_id)
      @bets_by_match[@prediction.match_id] = @prediction if @prediction&.errors&.any?
      @bet_results = Bolao::BetResults.call(bets)
      render :index, status:
    end

    def my_bets
      policy_scope(Bolao::Prediction, policy_scope_class: Bolao::BetPolicy::Scope)
        .where(pool: @pool).includes(match: %i[home_team away_team])
        .references(:match).order('core_matches.match_date')
    end

    def open_matches
      Core::Match.where(championship_id: @pool.championship_id, status: %w[scheduled live])
                 .includes(:home_team, :away_team).order(:match_date).limit(UPCOMING_LIMIT)
    end
  end
end
