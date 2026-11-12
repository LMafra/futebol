ActiveAdmin.register_page 'Dashboard', namespace: :gestor do
  menu priority: 1, label: 'Painel'

  content title: 'Painel do gestor' do
    render partial: 'gestor/dashboard/index', locals: {
      overview: assigns[:overview],
      kpis: assigns[:kpis],
      queue: assigns[:queue]
    }
  end

  controller do
    before_action :load_overview, only: :index

    private

    def load_overview
      championships = helpers.gestor_championships.reorder(season: :desc, name: :asc)
      @overview = Gestor::ChampionshipOverview.call(championships)
      match_queue = Gestor::MatchQueue.call(Core::Match.where(championship_id: championships.map(&:id)))
      @queue = match_queue.items
      @kpis = match_queue.kpis
    end
  end
end
