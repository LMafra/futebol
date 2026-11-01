module Cartola
  # One per user and championship, opened with the championship's cartola_initial_budget.
  class Wallet < ApplicationRecord
    belongs_to :user, class_name: 'Core::User'
    belongs_to :championship, class_name: 'Core::Championship'

    validates :balance, numericality: { greater_than_or_equal_to: 0 }
    validates :user_id, uniqueness: { scope: :championship_id }

    def self.ransackable_attributes(_auth_object = nil) = %w[user_id championship_id balance]

    def self.for(user:, championship:)
      find_by(user:, championship:) ||
        create_or_find_by!(user:, championship:) { |wallet| wallet.balance = championship.cartola_initial_budget }
    end

    # Without creating the wallet: the balance it has, or the one it would open with.
    def self.balance_for(user:, championship:)
      find_by(user:, championship:)&.balance || championship.cartola_initial_budget
    end
  end
end
