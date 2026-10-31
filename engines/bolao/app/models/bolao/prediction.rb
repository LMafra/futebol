module Bolao
  class Prediction < ApplicationRecord
    include Discard::Model

    belongs_to :pool, class_name: 'Bolao::Pool'
    belongs_to :user, class_name: 'Core::User'
    belongs_to :match, class_name: 'Core::Match'
    has_many :scores, class_name: 'Bolao::PredictionScore', dependent: :restrict_with_error

    validates :home_guess, :away_guess, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end
