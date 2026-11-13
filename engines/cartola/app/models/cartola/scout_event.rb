module Cartola
  # Lance (ADR 0006): one scout of a player in a match, with the period and the minute when known. The counters of
  # Cartola::PlayerScore are the sum of the kept lances; undoing one marks discarded_at, nothing is deleted.
  class ScoutEvent < ApplicationRecord
    include Discard::Model

    STATS = PlayerScore::SCOUTS.map(&:to_s).freeze
    PERIODS = { 'first_half' => '1º tempo', 'second_half' => '2º tempo', 'extra_time' => 'Prorrogação',
                'penalties' => 'Pênaltis' }.freeze
    MINUTES = 0..130

    belongs_to :match, class_name: 'Core::Match'
    belongs_to :player, class_name: 'Core::Player'
    belongs_to :team, class_name: 'Core::Team'
    belongs_to :recorded_by, class_name: 'Core::User', optional: true

    validates :stat, inclusion: { in: STATS }
    validates :period, inclusion: { in: PERIODS.keys }, allow_nil: true
    validates :minute, numericality: { only_integer: true, in: MINUTES }, allow_nil: true

    # Match order: by period, then minute; lances without them (backfilled totals) first.
    scope :chronological, lambda {
      order(Arel.sql("array_position(ARRAY[#{PERIODS.keys.map { "'#{_1}'" }.join(',')}]::varchar[], period) " \
                     'NULLS FIRST'), Arel.sql('minute NULLS FIRST'), :id)
    }

    # The kept lances of a match, newest first (the timeline of the match pages).
    def self.timeline(match) = kept.where(match:).includes(:player).chronological.to_a.reverse

    def period_label = PERIODS[period]
  end
end
