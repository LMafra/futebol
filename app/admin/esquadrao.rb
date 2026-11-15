# Participantes › Esquadrão (Admin and Gestor): ranking, gabarito da rodada and the participants' lineups, which
# the organizer edits with a reason (Cartola::LineupCorrection). ?championship_id=, ?rodada=, ?escalacao=ID.
%i[admin gestor].each do |ns|
  ActiveAdmin.register_page 'Esquadrao', namespace: ns do
    menu parent: 'Participantes', label: 'Esquadrão', priority: 2

    content title: 'Esquadrão' do
      render partial: 'admin/esquadrao/page', locals: { championships: assigns[:championships], board: assigns[:board] }
    end

    page_action :update_lineup, method: :post do
      lineup = Cartola::Lineup.includes(:championship, squad: :user, lineup_players: { player: :team })
                              .find(params[:lineup_id])
      authorize! :correct, lineup
      fields = params.expect(lineup: [:formation, :captain_id, :reason, { player_ids: [] }]).to_h.symbolize_keys
      form = LineupCorrectionForm.new(**fields, lineup:, actor: current_user, ip_address: request.remote_ip)
      back = { championship_id: lineup.championship_id, rodada: lineup.round, escalacao: lineup.id }
      if form.save
        redirect_to "#{request.path.delete_suffix('/update_lineup')}?#{back.to_query}#lineups",
                    notice: "Escalação de #{lineup.squad.user.name.presence || lineup.squad.user} corrigida.",
                    status: :see_other
      else
        flash[:lineup_edit] = { 'lineup_id' => lineup.id, 'values' => fields.transform_keys(&:to_s),
                                'messages' => form.errors.full_messages }
        redirect_to "#{request.path.delete_suffix('/update_lineup')}?#{back.merge(editar: 1).to_query}",
                    status: :see_other
      end
    end

    controller do
      before_action :load_board, only: :index

      private

      def load_board
        scope = Core::Championship.order(season: :desc, name: :asc)
        @championships = active_admin_authorization.scope_collection(scope).to_a
        championship = @championships.find { _1.id == params[:championship_id].to_i } || @championships.first
        @board = championship && EsquadraoBoard.new(championship, round: params[:rodada])
      end
    end
  end
end
