module Bulk
  # Deletes the teams, players or scheduled matches that have no history and keeps the others, saying why. History
  # is whatever another table points at: deleting would lose it (or fail on the foreign key).
  class DestroyRecords
    CHECKS = {
      'Core::Team' => {
        ['tem partidas', 'têm partidas'] => lambda { |ids|
          ::Core::Match.where(home_team_id: ids).pluck(:home_team_id) +
            ::Core::Match.where(away_team_id: ids).pluck(:away_team_id)
        },
        ['tem jogadores', 'têm jogadores'] => ->(ids) { ::Core::Player.where(team_id: ids).pluck(:team_id) }
      },
      'Core::Player' => {
        ['tem lances', 'têm lances'] => ->(ids) { ::Cartola::ScoutEvent.where(player_id: ids).pluck(:player_id) },
        ['tem histórico no Esquadrão', 'têm histórico no Esquadrão'] => lambda { |ids|
          [::Cartola::PlayerScore, ::Cartola::LineupPlayer, ::Cartola::PlayerValueHistory, ::Cartola::PlayerValue]
            .flat_map { _1.where(player_id: ids).pluck(:player_id) }
        }
      },
      'Core::Match' => {
        ['não está agendada', 'não estão agendadas'] => lambda { |ids|
          ::Core::Match.where(id: ids).where.not(status: 'scheduled').pluck(:id)
        },
        ['tem palpites', 'têm palpites'] => ->(ids) { ::Bolao::Prediction.where(match_id: ids).pluck(:match_id) },
        ['tem lances', 'têm lances'] => lambda { |ids|
          [::Cartola::ScoutEvent, ::Cartola::PlayerScore, ::Cartola::PlayerValueHistory]
            .flat_map { _1.where(match_id: ids).pluck(:match_id) }
        }
      }
    }.freeze

    def self.call(records, actor:, ip_address:) = new(records, actor:, ip_address:).call

    def initialize(records, actor:, ip_address:)
      @records = records.to_a
      @actor = actor
      @ip_address = ip_address
      @report = Report.new(done: %w[excluído excluídos])
    end

    def call
      reasons = blocking_reasons
      Bulk.one_by_one do
        @records.each do |record|
          reason = reasons[record.id]
          reason ? @report.keep!(record, reason) : destroy(record)
        end
      end
      @report
    end

    private

    # The first reason that holds for each record id, in the order of CHECKS.
    def blocking_reasons
      ids = @records.map(&:id)
      CHECKS.fetch(@records.first&.class&.name, {}).reverse_each.with_object({}) do |(reason, check), found|
        check.call(ids).uniq.each { found[_1] = reason }
      end
    end

    def destroy(record)
      record.transaction do
        ::Core::AuditLog.create!(action: "#{record.model_name.element}.destroyed", user: @actor, auditable: record,
                                 ip_address: @ip_address, metadata: { name: record.to_s, bulk: true })
        record.destroy!
      end
      @report.done!(record)
    end
  end
end
