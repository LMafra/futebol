module Cartola
  # Cartola rankings of a championship (?championship_id=, default the latest), one tab each: ?tab=points|coins.
  class RankingsController < ::ApplicationController
    TABS = { 'points' => 'Pontos', 'coins' => 'Cartoletas' }.freeze

    def show
      authorize %i[cartola ranking], :show?
      @championships = Core::Championship.order(season: :desc, name: :asc).to_a
      @championship = selected_championship
      @tab = TABS.key?(params[:tab]) ? params[:tab] : TABS.keys.first
      @rows = @championship ? ranking_rows : []
    end

    private

    def ranking_rows
      @tab == 'coins' ? Cartola::RankingsService.coins(@championship) : Cartola::RankingsService.points(@championship)
    end

    def selected_championship
      return @championships.first if params[:championship_id].blank?

      @championships.find { |championship| championship.id == params[:championship_id].to_i } ||
        raise(ActiveRecord::RecordNotFound, 'Campeonato não encontrado')
    end
  end
end
