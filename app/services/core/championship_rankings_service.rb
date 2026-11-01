module Core
  # Public rankings of championships (home and /campeonatos/:id), in batch: two grouped queries and one load of
  # users, whatever the number of championships.
  #   bolao:     per user, the best kept PredictionScore of each match (betting in several pools counts once),
  #              summed over the championship;
  #   esquadrao: Cartola::RankingsService points (the captain's twice), per championship.
  # Ties share the position (1, 1, 3); names follow Core::User#public_display_name, so no e-mail leaks.
  module ChampionshipRankingsService
    Row = Data.define(:position, :user_name, :points) do
      def name = user_name
    end

    # { championship_id => { bolao: [Row], esquadrao: [Row] } }; limit: nil gives the full rankings.
    def self.top(championships, limit: 3)
      ids = championships.map(&:id)
      totals = { bolao: bolao_totals(ids), esquadrao: esquadrao_totals(ids) }
      names = public_names(totals.values.flat_map { |module_totals| module_totals.keys.map(&:last) })
      ids.index_with do |championship_id|
        totals.transform_values { |module_totals| ranked(module_totals, championship_id, names, limit) }
      end
    end

    def self.bolao(championship, limit: nil) = top([championship], limit:).fetch(championship.id).fetch(:bolao)

    def self.esquadrao(championship, limit: nil) = top([championship], limit:).fetch(championship.id).fetch(:esquadrao)

    # { [championship_id, user_id] => points }
    def self.bolao_totals(ids)
      best = Bolao::PredictionScore.kept.joins(prediction: :match).merge(Bolao::Prediction.kept)
                                   .where(core_matches: { championship_id: ids })
                                   .group('core_matches.championship_id', 'bolao_predictions.user_id',
                                          'bolao_predictions.match_id')
                                   .select('core_matches.championship_id, bolao_predictions.user_id, ' \
                                           'MAX(bolao_prediction_scores.points) AS best')
      Bolao::PredictionScore.unscoped.from(best, :best).group('best.championship_id', 'best.user_id')
                            .sum('best.best')
    end

    def self.esquadrao_totals(ids)
      Cartola::Lineup.where(championship_id: ids).joins(:squad, :lineup_players)
                     .joins(Cartola::RankingsService::SCORES_JOIN)
                     .group('cartola_lineups.championship_id', 'cartola_squads.user_id')
                     .sum(Arel.sql(Cartola::RankingsService::POINTS_SUM))
    end

    def self.public_names(user_ids)
      Core::User.where(id: user_ids.uniq).to_h { |user| [user.id, user.public_display_name] }
    end

    def self.ranked(totals, championship_id, names, limit)
      entries = totals.filter_map do |(id, user_id), points|
        [names.fetch(user_id), user_id, points] if id == championship_id
      end
      rows = positioned(entries.sort_by { |name, user_id, points| [-points, name, user_id] })
      limit ? rows.first(limit) : rows
    end

    def self.positioned(sorted)
      sorted.each_with_index.with_object([]) do |((name, _user_id, points), index), rows|
        position = rows.last&.points == points ? rows.last.position : index + 1
        rows << Row.new(position:, user_name: name, points:)
      end
    end

    private_class_method :bolao_totals, :esquadrao_totals, :public_names, :ranked, :positioned
  end
end
