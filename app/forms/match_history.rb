# "Histórico da partida" on the single match page of /admin and /gestor (TICKET-0112): the latest Core::AuditLog
# entries of the match, newest first, and the names of the players they mention.
class MatchHistory
  LIMIT = 100

  def initialize(match)
    @match = match
  end

  def logs
    @logs ||= Core::AuditLog.where(auditable: @match).includes(:user).order(created_at: :desc, id: :desc)
                            .limit(LIMIT).to_a
  end

  def players
    @players ||= Core::Player.where(id: logs.filter_map { _1.metadata.to_h['player_id'] }.uniq).pluck(:id, :name).to_h
  end
end
