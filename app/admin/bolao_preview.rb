ActiveAdmin.register_page 'BolaoPreview' do
  menu false
  breadcrumb { match_crumbs(@match) }

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
      @matches = matches_with_teams.where.not(status: 'scheduled').order(match_date: :desc)
      return if params[:match_id].blank?

      @match = matches_with_teams.find(params[:match_id])
      authorize! :preview, @match
      load_candidates
    end

    def load_candidates
      @candidate_home, @candidate_away = params.values_at(:candidate_home, :candidate_away)
      calculate_preview if @candidate_home.present? || @candidate_away.present?
    end

    def matches_with_teams = Core::Match.includes(:home_team, :away_team)

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
