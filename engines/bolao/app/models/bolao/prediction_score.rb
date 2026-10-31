module Bolao
  class PredictionScore < ApplicationRecord
    include Discard::Model

    belongs_to :prediction, class_name: 'Bolao::Prediction'

    validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :scoring_token, presence: true
  end
end
