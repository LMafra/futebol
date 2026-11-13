module Bolao
  # ::ApplicationController: inside Bolao, the bare constant resolves to the engine's Bolao::ApplicationController.
  class PoolsController < ::ApplicationController
    rescue_from Pundit::NotAuthorizedError do |exception|
      render_forbidden(exception, message: 'Este bolão é restrito aos participantes.')
    end

    before_action :set_pool, only: %i[show destroy]

    def index
      render_index
    end

    def show
      authorize @pool
      @memberships = @pool.memberships.includes(:user).order(:joined_at)
    end

    def new
      @pool = Bolao::Pool.new
      authorize @pool
      render_new
    end

    def create
      @pool = Bolao::Pool.new(pool_params.merge(owner: current_user))
      authorize @pool

      if @pool.save
        redirect_to pool_path(@pool), notice: "Bolão criado. Compartilhe o código #{@pool.code}."
      else
        render_new(status: :unprocessable_content)
      end
    end

    def join
      authorize Bolao::Pool, :join?
      pool = Bolao::Pool.find_by(code: Bolao::Pool.normalize_code(params[:code]))
      return render_index(error: 'Código de bolão inválido.') unless pool

      if pool.memberships.create(user: current_user).persisted?
        redirect_to pool_path(pool), notice: "Você entrou no bolão #{pool.name}."
      else
        render_index(error: 'Você já participa deste bolão.')
      end
    rescue ActiveRecord::RecordNotUnique
      render_index(error: 'Você já participa deste bolão.')
    end

    def destroy
      authorize @pool

      if @pool.destroy
        redirect_to pools_path, notice: 'Bolão removido.', status: :see_other
      else
        redirect_to pool_path(@pool), alert: @pool.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_pool
      @pool = Bolao::Pool.find(params[:id])
    end

    def pool_params
      params.expect(pool: %i[name championship_id])
    end

    def render_index(error: nil)
      @pools = policy_scope(Bolao::Pool).includes(:championship).order(:name)
      @error = error
      render :index, status: error ? :unprocessable_content : :ok
    end

    def render_new(status: :ok)
      @championships = Core::Championship.published.order(season: :desc, name: :asc)
      render :new, status:
    end
  end
end
