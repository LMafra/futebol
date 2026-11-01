ActiveAdmin.register_page 'MatchFinalizer' do
  menu parent: 'Pontuação', label: 'Finalizar partida', priority: 2

  content title: 'Finalizar partida' do
    render partial: 'admin/match_finalizer/form',
           locals: { matches: assigns[:matches], match: assigns[:match], form: assigns[:form] }
  end

  page_action :finalize, method: :post do
    load_matches
    @match = Core::Match.includes(:home_team, :away_team).find(params.dig(:finalization, :match_id))
    authorize! :finalize, @match
    audit = { actor: current_user, ip_address: request.remote_ip }
    @form = MatchFinalizationForm.new(**finalization_params, **audit, match: @match)

    if @form.save
      notice = "Partida finalizada em #{admin_score_text}; pontuação enfileirada."
      redirect_to admin_match_path(@match), status: :see_other, notice:
    else
      render_page status: :unprocessable_content
    end
  end

  controller do
    include AdminPageForm

    before_action :load_page, only: :index

    private

    def load_page
      load_matches
      return if params[:match_id].blank?

      @match = Core::Match.includes(:home_team, :away_team).find(params[:match_id])
      authorize! :finalize, @match
      @form = MatchFinalizationForm.new(match: @match, **params.permit(:home_score, :away_score).to_h.symbolize_keys)
    end

    def load_matches
      @matches = Core::Match.where(status: 'live')
                            .or(Core::Match.where(status: 'scheduled', match_date: ..Time.current))
                            .includes(:home_team, :away_team).order(:match_date)
    end

    def finalization_params
      params.expect(finalization: %i[home_score away_score score_confirmation]).to_h.symbolize_keys
    end

    def admin_score_text = "#{@match.home_score} × #{@match.away_score}"
  end
end
