%i[admin gestor].each do |ns|
  ActiveAdmin.register_page 'MatchScouts', namespace: ns do
    menu false
    breadcrumb { match_crumbs(@match) }

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
        redirect_to helpers.scoring_path('matchscouts', match_id: @match.id), status: :see_other, notice:
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

      def load_matches
        base = Core::Match.where.not(status: 'scheduled')
                          .or(Core::Match.where(status: 'scheduled', match_date: ..Time.current))
        @matches = active_admin_authorization.scope_collection(
          base.includes(:home_team, :away_team).order(match_date: :desc)
        )
      end

      def scout_rows
        highlight = params[:highlight].to_s
        fields = [:team_id, :played, *Cartola::PlayerScore::SCOUTS]
        params.fetch(:scouts, {}).each_pair.map do |player_id, row|
          row.permit(*fields).to_h.symbolize_keys.merge(player_id: player_id.to_i, highlight: player_id == highlight)
        end
      end
    end
  end
end
