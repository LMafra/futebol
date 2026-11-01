module Bolao
  class Prediction < ApplicationRecord
    include Discard::Model

    belongs_to :pool, class_name: 'Bolao::Pool'
    belongs_to :user, class_name: 'Core::User'
    belongs_to :match, class_name: 'Core::Match'
    has_many :scores, class_name: 'Bolao::PredictionScore', dependent: :restrict_with_error

    validates :home_guess, :away_guess, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :match_id, uniqueness: { scope: %i[pool_id user_id], conditions: -> { kept } }
    # Bound to :create/:update so importing past predictions (seeds) can save with context: :backfill.
    validate :match_open_for_bets, on: %i[create update], if: :bet_changed?

    private

    def bet_changed?
      new_record? || will_save_change_to_match_id? || will_save_change_to_home_guess? ||
        will_save_change_to_away_guess?
    end

    def match_open_for_bets
      return if match.nil? || match.status == 'scheduled'

      errors.add(:base, :bets_closed, message: 'Palpites encerrados para esta partida.')
    end
  end
end
