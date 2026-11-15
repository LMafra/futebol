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
      @show_code = reveal_pool_code?(@pool)
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

    def render_index(error: nil)
      @query = params[:q].to_s.strip
      @pools = filtered_pools.to_a
      @pool_cards = Users::PoolCardBuilder.new(current_user, @pools).cards
      @error = error
      @index_state = index_state_for(error)
      render :index, status: error ? :unprocessable_content : :ok
    end

    def index_state_for(error)
      return :error if error
      return :empty if @pools.empty?

      :default
    end

    def filtered_pools
      scope = policy_scope(Bolao::Pool).includes(:championship, :memberships).order(:name)
      return scope if @query.blank?

      pattern = "%#{Bolao::Pool.sanitize_sql_like(@query)}%"
      scope.where('bolao_pools.name ILIKE ?', pattern)
    end

    def reveal_pool_code?(pool)
      current_user.admin? || current_user.manager? || pool.owned_by?(current_user)
    end
  end
end
