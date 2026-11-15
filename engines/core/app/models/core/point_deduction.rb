module Core
  # Dedução de pontos: points taken from an enrolled team in a championship's standings, with a reason shown on the
  # public table. Revoking marks revoked_at and revoked_by; nothing is deleted.
  class PointDeduction < ApplicationRecord
    REASON_MAX = 200

    belongs_to :championship, class_name: 'Core::Championship', inverse_of: :point_deductions
    belongs_to :team, class_name: 'Core::Team'
    belongs_to :created_by, class_name: 'Core::User'
    belongs_to :revoked_by, class_name: 'Core::User', optional: true

    validates :points, numericality: { only_integer: true, greater_than: 0 }
    validates :reason, presence: true, length: { maximum: REASON_MAX }
    validate :team_enrolled, on: :create

    scope :active, -> { where(revoked_at: nil).order(:created_at, :id) }

    def revoked? = revoked_at.present?

    def revoke!(actor) = update!(revoked_at: Time.current, revoked_by: actor)

    private

    def team_enrolled
      return if championship.nil? || team_id.nil? || championship.championship_teams.exists?(team_id:)

      errors.add(:team_id, :not_enrolled, message: 'não está inscrito neste campeonato')
    end
  end
end
