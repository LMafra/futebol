module Cartola
  # Participantes › Esquadrão: the organizer edits a participant's lineup (players, captain, formation), with the
  # reason in the AuditLog. It goes through Cartola::WalletService like the owner's edit, so the wallet keeps
  # matching the players held; the rankings read the lineup, so the points follow at once.
  class LineupCorrection
    # picks: { formation:, captain_id:, player_ids: }. Returns false with the reason in lineup.errors.
    def self.call(lineup:, picks:, reason:, actor:, ip_address:)
      new(lineup, actor:, ip_address:).call(picks, reason:)
    end

    def initialize(lineup, actor:, ip_address:)
      @lineup = lineup
      @actor = actor
      @ip_address = ip_address
    end

    def call(picks, reason:)
      before = snapshot
      assign(picks)
      Lineup.transaction do
        next false unless WalletService.save(@lineup)

        audit!(before:, reason:)
        true
      end
    end

    private

    def assign(picks)
      @lineup.formation = picks[:formation]
      @lineup.assign_players(available_players.where(id: Array(picks[:player_ids])).to_a)
      @lineup.assign_captain(picks[:captain_id])
    end

    def available_players
      Core::Player.where(team: @lineup.championship.teams)
                  .or(Core::Player.where(id: @lineup.lineup_players.map(&:player_id))).includes(:team)
    end

    def snapshot
      { formation: @lineup.formation, captain_id: @lineup.captain_id,
        player_ids: @lineup.selected_players.map(&:id).sort }
    end

    def audit!(before:, reason:)
      Core::AuditLog.create!(action: 'esquadrao.lineup_corrected', user: @actor, auditable: @lineup,
                             ip_address: @ip_address,
                             metadata: { user_id: @lineup.squad.user_id, round: @lineup.round, before:,
                                         after: snapshot, reason: })
    end
  end
end
