module Bulk
  # Enrolls several teams in a championship, or takes them out of it (Inscrição, ADR 0006). The rules stay in
  # Core::ChampionshipTeam: same manager on both sides, and a team with matches stays enrolled.
  class Enrollment
    def self.enroll(teams, championship:) = new(teams, championship).enroll
    def self.unenroll(teams, championship:) = new(teams, championship).unenroll

    def initialize(teams, championship)
      @teams = teams
      @championship = championship
    end

    def enroll
      report = Report.new(done: %w[inscrito inscritos], kept: ['não inscrito', 'não inscritos'])
      Bulk.one_by_one do
        @teams.each do |team|
          enrollment = ::Core::ChampionshipTeam.new(championship: @championship, team:)
          enrollment.save ? report.done!(team) : report.keep!(team, enroll_reason(enrollment))
        end
      end
      report
    end

    def unenroll
      report = Report.new(done: %w[removido removidos])
      enrollments = @championship.championship_teams.where(team: @teams).index_by(&:team_id)
      Bulk.one_by_one do
        @teams.each do |team|
          reason = unenroll_reason(enrollments[team.id])
          reason ? report.keep!(team, reason) : report.done!(team)
        end
      end
      report
    end

    private

    def enroll_reason(enrollment)
      return ['já estava inscrito', 'já estavam inscritos'] if enrollment.errors.of_kind?(:team_id, :taken)

      ['pertence a outro gestor', 'pertencem a outro gestor']
    end

    def unenroll_reason(enrollment)
      return ['não estava inscrito', 'não estavam inscritos'] unless enrollment
      return if enrollment.destroy

      ['tem partidas neste campeonato', 'têm partidas neste campeonato']
    end
  end
end
