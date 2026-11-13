module Core
  # Inscrição: a team taking part in a championship run by the team's own manager (nil on both = the admin).
  class ChampionshipTeam < ApplicationRecord
    belongs_to :championship, class_name: 'Core::Championship', inverse_of: :championship_teams
    belongs_to :team, class_name: 'Core::Team', inverse_of: :championship_teams

    validates :team_id, uniqueness: { scope: :championship_id, message: 'já está inscrito neste campeonato' }
    validate :same_manager, on: :create
    before_destroy :ensure_no_matches

    private

    def same_manager
      return if championship.nil? || team.nil? || championship.manager_id == team.manager_id

      errors.add(:team, 'pertence a outro gestor')
    end

    def ensure_no_matches
      return unless championship.matches.exists?(['home_team_id = :id OR away_team_id = :id', { id: team_id }])

      errors.add(:base, "#{team} já tem partidas neste campeonato")
      throw :abort
    end
  end
end
