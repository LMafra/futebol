module Core
  class Match < ApplicationRecord
    STATUSES = %w[scheduled live finished scored].freeze

    belongs_to :home_team, class_name: 'Core::Team', inverse_of: :home_matches
    belongs_to :away_team, class_name: 'Core::Team', inverse_of: :away_matches
    belongs_to :championship, class_name: 'Core::Championship'

    validates :match_date, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                                        allow_nil: true
    validates :external_id, presence: true, uniqueness: true
    validates :scores_calculated_at, presence: true, if: -> { status == 'scored' }
    validates :scores_calculated_at, absence: true, unless: -> { status == 'scored' }
    validate :teams_must_differ

    def to_s = "#{home_team} x #{away_team}"

    private

    def teams_must_differ
      return if home_team_id.blank? || home_team_id != away_team_id

      errors.add(:away_team, :must_differ_from_home_team, message: 'deve ser diferente do mandante')
    end
  end
end
