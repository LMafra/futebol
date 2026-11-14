module Bulk
  # Moves players to another team, keeping their history (lances and Esquadrão points stay with the player).
  class MovePlayers
    def self.call(players, team:, actor:, ip_address:) = new(players, team:, actor:, ip_address:).call

    def initialize(players, team:, actor:, ip_address:)
      @players = players
      @team = team
      @actor = actor
      @ip_address = ip_address
      @report = Report.new(done: %w[movido movidos])
    end

    def call
      Bulk.one_by_one do
        @players.each do |player|
          reason = reason_to_keep(player) || move(player)
          @report.keep!(player, reason) if reason
        end
      end
      @report
    end

    private

    def reason_to_keep(player)
      ['já está no time', 'já estão no time'] if player.team_id == @team.id
    end

    def move(player)
      from = player.team.to_s
      player.transaction do
        return ['tem o número de outro jogador do time', 'têm o número de outro jogador do time'] unless
          player.update(team: @team)

        ::Core::AuditLog.create!(action: 'player.moved', user: @actor, auditable: player, ip_address: @ip_address,
                                 metadata: { from:, to: @team.to_s })
      end
      @report.done!(player)
      nil
    end
  end
end
