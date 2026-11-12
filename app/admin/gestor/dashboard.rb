ActiveAdmin.register_page 'Dashboard', namespace: :gestor do
  menu priority: 1, label: 'Painel'

  content title: 'Painel do gestor' do
    render partial: 'gestor/dashboard/index', locals: {
      overview: assigns[:overview],
      kpis: assigns[:kpis],
      upcoming: assigns[:upcoming]
    }
  end

  controller do
    before_action :load_overview, only: :index

    private

    def load_overview
      championships = helpers.gestor_championships.reorder(season: :desc, name: :asc)
      @overview = Gestor::ChampionshipOverview.call(championships)
      matches = Core::Match.where(championship_id: championships.map(&:id))
      @kpis = kpi_counts(matches)
      @upcoming = upcoming_matches(matches)
    end

    def kpi_counts(matches)
      {
        teams: @overview.sum(&:teams),
        players: @overview.sum(&:players),
        pending_matches: matches.where(status: 'finished', scores_calculated_at: nil).count
      }
    end

    def upcoming_matches(matches)
      scoped = matches.includes(:home_team, :away_team)
      upcoming = scoped.where(status: 'scheduled').order(:match_date).limit(8)
      return upcoming if upcoming.any?

      scoped.where(status: %w[live finished], scores_calculated_at: nil).order(:match_date).limit(8)
    end
  end
end
