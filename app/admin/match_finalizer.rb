# The old "Finalizar partida" page: the match page (AdminMatchBoard) finalizes in a dialog, opened by ?modal=finalize.
%i[admin gestor].each do |ns|
  ActiveAdmin.register_page 'MatchFinalizer', namespace: ns do
    menu false

    controller do
      def index
        match = params[:match_id].presence && Core::Match.find(params[:match_id])
        target = match ? "#{helpers.scoring_match_path(match)}?modal=finalize" : helpers.scoring_path('matches')
        redirect_to target
      end
    end
  end
end
