module Cartola
  # Cartola rankings of a championship, best first; ties share the position (1, 1, 3).
  #   points: kept PlayerScore points of each lineup's players in the matches of the lineup's round, per user;
  #           the captain's count twice, negative ones included (a captain who did not play has no PlayerScore);
  #   coins:  wallet balances.
  module RankingsService
    Row = Data.define(:position, :user, :value)

    SCORES_JOIN = <<~SQL.squish.freeze
      LEFT JOIN core_matches ON core_matches.championship_id = cartola_lineups.championship_id
        AND core_matches.round = cartola_lineups.round
      LEFT JOIN cartola_player_scores ON cartola_player_scores.player_id = cartola_lineup_players.player_id
        AND cartola_player_scores.match_id = core_matches.id AND cartola_player_scores.discarded_at IS NULL
    SQL
    POINTS_SUM = <<~SQL.squish.freeze
      COALESCE(cartola_player_scores.points, 0) * CASE WHEN cartola_lineup_players.captain THEN 2 ELSE 1 END
    SQL

    def self.points(championship)
      totals = Lineup.where(championship:).joins(:squad, :lineup_players).joins(SCORES_JOIN)
                     .group('cartola_squads.user_id').sum(Arel.sql(POINTS_SUM))
      users = Core::User.where(id: totals.keys).index_by(&:id)
      ranked(totals.map { |user_id, total| [users.fetch(user_id), total] })
    end

    def self.coins(championship)
      ranked(Wallet.where(championship:).includes(:user).map { |wallet| [wallet.user, wallet.balance] })
    end

    def self.ranked(entries)
      sorted = entries.sort_by { |user, value| [-value, user.name.to_s, user.id] }
      sorted.each_with_index.with_object([]) do |((user, value), index), rows|
        position = rows.last&.value == value ? rows.last.position : index + 1
        rows << Row.new(position:, user:, value:)
      end
    end

    private_class_method :ranked
  end
end
