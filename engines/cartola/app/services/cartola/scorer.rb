module Cartola
  module Scorer
    BONUSES = { goals: :goal_points, assists: :assist_points, clean_sheet: :clean_sheet_points,
                penalty_saves: :penalty_save_points, saves: :save_points }.freeze
    PENALTIES = { yellow_cards: :yellow_card_penalty, red_cards: :red_card_penalty,
                  own_goals: :own_goal_penalty }.freeze
    FLAGS = { played: :played_points, highlight: :highlight_points }.freeze

    # stats: { goals:, assists:, clean_sheet:, penalty_saves:, saves:, yellow_cards:, red_cards:, own_goals:,
    # played:, highlight: } (missing keys count as 0/false); rules responds to the Cartola::ScoringRule columns.
    # G×gol + A×assist + SG×sg + DP×dp + DE×de − CA×ca − CV×cv − GC×gc (+ Jogou, + Destaque); may be negative.
    def self.points(stats:, rules:)
      weighted(stats, rules, BONUSES) - weighted(stats, rules, PENALTIES) + weighted(stats, rules, FLAGS)
    end

    def self.weighted(stats, rules, columns)
      columns.sum { |stat, column| count(stats.fetch(stat, 0)) * rules.public_send(column) }
    end

    def self.count(value) = { true => 1, false => 0, nil => 0 }.fetch(value, value)

    private_class_method :weighted, :count
  end
end
