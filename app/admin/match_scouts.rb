ActiveAdmin.register_page 'MatchScouts' do
  menu parent: 'Pontuação', label: 'Scouts da partida', priority: 2

  content title: 'Scouts da partida' do
    render partial: 'admin/match_scouts/form',
           locals: { matches: assigns[:matches], match: assigns[:match], sheet: assigns[:sheet],
                     errors: assigns[:errors] || [] }
  end

  page_action :record, method: :post do
    load_matches
    @match = Core::Match.includes(:home_team, :away_team).find(params[:match_id])
    authorize! :record_scouts, @match
    rows = scout_rows
    result = Cartola::RecordScoutsService.call(match: @match, rows:, actor: current_user,
                                               ip_address: request.remote_ip)

    if result.success?
      notice = "Scouts salvos · placar #{helpers.admin_score(@match.reload)}."
      redirect_to admin_matchscouts_path(match_id: @match.id), status: :see_other, notice:
    else
      @errors = result.errors
      @sheet = MatchScoutSheet.new(match: @match, submitted: rows)
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
      authorize! :record_scouts, @match
      @sheet = MatchScoutSheet.new(match: @match)
    end

    # Matches that have kicked off; scored ones open read-only.
    def load_matches
      @matches = Core::Match.where.not(status: 'scheduled')
                            .or(Core::Match.where(status: 'scheduled', match_date: ..Time.current))
                            .includes(:home_team, :away_team).order(match_date: :desc)
    end

    # scouts[<player_id>][team_id|goals|…|played] and highlight=<player_id> (one radio for the whole match).
    def scout_rows
      highlight = params[:highlight].to_s
      fields = [:team_id, :played, *Cartola::PlayerScore::SCOUTS]
      params.fetch(:scouts, {}).each_pair.map do |player_id, row|
        row.permit(*fields).to_h.symbolize_keys.merge(player_id: player_id.to_i, highlight: player_id == highlight)
      end
    end
  end
end
