module Cartola
  # Session-scoped first-visit tour for Esquadrão lineups.
  module LineupTour
    extend ActiveSupport::Concern

    included do
      helper_method :show_esquadrao_tour?
    end

    private

    def dismiss_tour_if_requested
      return unless params[:pular_tour] == '1'

      session[:esquadrao_tour_dismissed] = true
      redirect_to main_app.lineup_path(request.query_parameters.except('pular_tour'))
    end

    def show_esquadrao_tour?
      session[:esquadrao_tour_dismissed].blank? && !@lineup.persisted?
    end
  end
end
