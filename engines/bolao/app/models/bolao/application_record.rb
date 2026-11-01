module Bolao
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Ransack (ActiveAdmin filters): nothing is searchable unless a model allowlists it.
    def self.ransackable_attributes(_auth_object = nil) = []
    def self.ransackable_associations(_auth_object = nil) = []
  end
end
