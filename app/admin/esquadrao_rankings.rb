ActiveAdmin.register_page 'EsquadraoRankings' do
  menu parent: 'Esquadrão', label: 'Rankings'

  content title: 'Rankings do Esquadrão' do
    render partial: 'admin/esquadrao_rankings/rankings',
           locals: { championships: assigns[:championships], championship: assigns[:championship],
                     points: assigns[:points], coins: assigns[:coins] }
  end

  controller do
    before_action :load_rankings, only: :index

    private

    def load_rankings
      @championships = Core::Championship.order(season: :desc, name: :asc).to_a
      @championship = @championships.find { |championship| championship.id == params[:championship_id].to_i } ||
                      @championships.first
      return unless @championship

      @points = Cartola::RankingsService.points(@championship)
      @coins = Cartola::RankingsService.coins(@championship)
    end
  end
end
