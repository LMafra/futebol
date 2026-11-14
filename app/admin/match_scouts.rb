# The old "Scouts da partida" page: the lances are now recorded on the match page (AdminMatchBoard).
%i[admin gestor].each do |ns|
  ActiveAdmin.register_page 'MatchScouts', namespace: ns do
    menu false

    controller do
      def index
        match = params[:match_id].presence && Core::Match.find(params[:match_id])
        redirect_to match ? helpers.scoring_match_path(match) : helpers.scoring_path('matches')
      end
    end
  end
end
