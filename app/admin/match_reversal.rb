ActiveAdmin.register_page 'MatchReversal' do
  menu parent: 'Pontuação', label: 'Reverter pontuação', priority: 3

  content title: 'Reverter pontuação' do
    render partial: 'admin/match_reversal/form',
           locals: { matches: assigns[:matches], match: assigns[:match], form: assigns[:form] }
  end

  page_action :revert, method: :post do
    load_matches
    @match = Core::Match.find(params.dig(:reversal, :match_id))
    authorize! :revert, @match
    @form = MatchReversalForm.new(reason: params.dig(:reversal, :reason), match: @match, actor: current_user,
                                  ip_address: request.remote_ip)

    if @form.save
      redirect_to admin_match_path(@match), status: :see_other,
                                            notice: 'Reversão enfileirada: os pontos serão descartados e auditados.'
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

      @match = Core::Match.find(params[:match_id])
      authorize! :revert, @match
      @form = MatchReversalForm.new(match: @match)
    end

    def load_matches
      @matches = Core::Match.where(status: %w[scored finished]).where.not(scores_calculated_at: nil)
                            .includes(:home_team, :away_team).order(match_date: :desc)
    end
  end
end
