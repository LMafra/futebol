ActiveAdmin.register_page 'BolaoPreview' do
  menu parent: 'Pontuação', label: 'Preview do Bolão', priority: 1

  content title: 'Preview do Bolão' do
    render partial: 'admin/bolao_preview/panel', locals: {
      matches: assigns[:matches], match: assigns[:match], preview: assigns[:preview],
      preview_error: assigns[:preview_error], pools: assigns[:pools], users: assigns[:users],
      candidate_home: assigns[:candidate_home], candidate_away: assigns[:candidate_away]
    }
  end

  controller do
    before_action :load_preview, only: :index

    private

    def load_preview
      @matches = Core::Match.where.not(status: 'scheduled').includes(:home_team, :away_team).order(match_date: :desc)
      return if params[:match_id].blank?

      @match = Core::Match.find(params[:match_id])
      authorize! :preview, @match
      @candidate_home, @candidate_away = params.values_at(:candidate_home, :candidate_away)
      calculate_preview if @candidate_home.present? || @candidate_away.present?
    end

    def calculate_preview
      @preview = Bolao::CalculatePreviewService.call(match: @match, candidate_home: @candidate_home,
                                                     candidate_away: @candidate_away)
      @pools = Bolao::Pool.where(id: @preview.rows.map(&:pool_id)).index_by(&:id)
      @users = Core::User.where(id: @preview.rows.map(&:user_id)).index_by(&:id)
    rescue ArgumentError
      @preview_error = 'Informe os dois placares candidatos como números inteiros, a partir de 0.'
    end
  end
end
