module Users
  # Assembles KPIs, pending actions, pools and simulator link for /minha-area.
  class DashboardData
    OPEN_MATCH_STATUSES = %w[scheduled live].freeze

    PoolCard = Data.define(:pool, :position, :members_count)

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def open_predictions_count = open_prediction_slots.size

    def lineup_ready?
      return false unless championship

      lineup = squad&.lineups&.find_by(championship:, round: current_round)
      lineup&.persisted? && lineup.lineup_players.any?
    end

    def esquadrao_position
      return unless championship

      Cartola::RankingsService.points(championship).find { |entry| entry.user.id == user.id }&.position
    end

    def action_center_groups
      Users::DashboardPendencies.new(self).groups
    end

    def pool_cards
      pools.map do |pool|
        standing = PoolParticipants.new(pool).ranking.find { |row| row.member.id == user.id }
        PoolCard.new(pool:, position: standing&.position, members_count: pool.memberships.size)
      end
    end

    def simulator_championship
      pools.min_by { |pool| pool.name.to_s.downcase }&.championship || championship
    end

    def championship
      @championship ||= pools.filter_map(&:championship).max_by { |c| [c.season, c.id] } ||
                        Core::Championship.latest
    end

    def current_round
      @current_round ||= resolve_current_round
    end

    def pools
      @pools ||= Bolao::Pool.joins(:memberships)
                            .where(bolao_pool_memberships: { user_id: user.id })
                            .includes(:championship, :memberships)
                            .distinct.order(:name).to_a
    end

    def open_prediction_slots
      @open_prediction_slots ||= build_open_prediction_slots
    end

    private

    def squad
      @squad ||= Cartola::Squad.find_by(user:)
    end

    def resolve_current_round
      return 1 unless championship

      matches = championship.matches.to_a
      open_match = matches.find { |match| usable_open_round?(match) }
      open_match&.round || matches.filter_map(&:round).max || 1
    end

    def usable_open_round?(match)
      match.round.present? && match.status.in?(OPEN_MATCH_STATUSES)
    end

    def build_open_prediction_slots
      slots = pools.flat_map { |pool| open_slots_for(pool) }
      slots.sort_by { |slot| slot.fetch(:match).match_date || Time.zone.at(0) }
    end

    def open_slots_for(pool)
      predicted_ids = Bolao::Prediction.kept.where(pool:, user:).pluck(:match_id)
      open_matches_for(pool).reject { |match| predicted_ids.include?(match.id) }
                            .map { |match| { pool:, match: } }
    end

    def open_matches_for(pool)
      Core::Match.where(championship_id: pool.championship_id, status: OPEN_MATCH_STATUSES)
                 .includes(:home_team, :away_team)
                 .order(:match_date).limit(10)
    end
  end
end
