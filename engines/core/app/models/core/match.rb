module Core
  class Match < ApplicationRecord
    include AASM

    belongs_to :home_team, class_name: 'Core::Team', inverse_of: :home_matches
    belongs_to :away_team, class_name: 'Core::Team', inverse_of: :away_matches
    belongs_to :championship, class_name: 'Core::Championship'

    aasm column: :status, whiny_persistence: true do
      state :scheduled, initial: true
      state :live, :finished, :scored, :reverted

      event :start_match do
        transitions from: :scheduled, to: :live, guard: :kickoff_reached?
      end

      event :finish_match do
        transitions from: :live, to: :finished, guard: :final_score_present?
      end

      event :mark_scored do
        transitions from: %i[finished reverted], to: :scored, guard: :scores_pending?, after: :stamp_scores
      end

      # Guards run before transition `after` callbacks, and AASM persists once after them:
      # the guard sees scores_calculated_at still set, and the cleared values go out in the same save.
      event :revert_match do
        transitions from: %i[scored finished], to: :reverted, guard: :scores_calculated?, after: :clear_scores
      end
    end

    STATUSES = aasm.states.map { |state| state.name.to_s }.freeze

    validates :match_date, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                                        allow_nil: true
    validates :external_id, presence: true, uniqueness: true
    validates :round, numericality: { only_integer: true, in: 1..38 }, allow_nil: true
    validates :scores_calculated_at, presence: true, if: -> { status == 'scored' }
    validates :scores_calculated_at, absence: true, unless: -> { status.in?(%w[finished scored]) }
    validate :teams_must_differ
    validate :teams_enrolled, if: :teams_or_championship_changed?

    def self.ransackable_attributes(_auth_object = nil) = %w[status external_id match_date championship_id round]
    def self.ransackable_associations(_auth_object = nil) = %w[championship]

    def to_s = "#{home_team} x #{away_team}"

    def scores_calculated? = scores_calculated_at.present?

    private

    def kickoff_reached? = match_date.present? && match_date <= Time.current

    def final_score_present? = !home_score.nil? && !away_score.nil?

    def scores_pending? = scores_calculated_at.nil?

    def stamp_scores(scoring_token = SecureRandom.uuid)
      self.scores_calculated_at = Time.current
      self.scoring_token = scoring_token
    end

    def clear_scores(reversal_token = SecureRandom.uuid)
      self.scores_calculated_at = nil
      self.scoring_token = nil
      self.reversal_token = reversal_token
    end

    def teams_must_differ
      return if home_team_id.blank? || home_team_id != away_team_id

      errors.add(:away_team, :must_differ_from_home_team, message: 'deve ser diferente do mandante')
    end

    # Status changes on matches created before enrollments existed must not trip the check.
    def teams_or_championship_changed?
      new_record? || will_save_change_to_home_team_id? || will_save_change_to_away_team_id? ||
        will_save_change_to_championship_id?
    end

    def teams_enrolled
      return if championship.nil?

      enrolled = championship.championship_teams.where(team_id: [home_team_id, away_team_id]).pluck(:team_id)
      { home_team: home_team_id, away_team: away_team_id }.each do |attribute, team_id|
        next if team_id.nil? || enrolled.include?(team_id)

        errors.add(attribute, :not_enrolled, message: 'não está inscrito neste campeonato')
      end
    end
  end
end
